<script>
import { GlIcon, GlIntersectionObserver } from '@gitlab/ui';
import Visibility from 'visibilityjs';
import createFlash from '~/flash';
import Poll from '~/lib/utils/poll';
import { visitUrl } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';
import {
  IssuableStatus,
  IssuableStatusText,
  IssuableType,
  IssueTypePath,
  IncidentTypePath,
  IncidentType,
} from '../constants';
import eventHub from '../event_hub';
import getIssueStateQuery from '../queries/get_issue_state.query.graphql';
import Service from '../services/index';
import Store from '../stores';
import descriptionComponent from './description.vue';
import editedComponent from './edited.vue';
import formComponent from './form.vue';
import PinnedLinks from './pinned_links.vue';
import titleComponent from './title.vue';

export default {
  components: {
    GlIcon,
    GlIntersectionObserver,
    titleComponent,
    editedComponent,
    formComponent,
    PinnedLinks,
  },
  props: {
    endpoint: {
      required: true,
      type: String,
    },
    updateEndpoint: {
      required: true,
      type: String,
    },
    canUpdate: {
      required: true,
      type: Boolean,
    },
    canDestroy: {
      required: true,
      type: Boolean,
    },
    showInlineEditButton: {
      type: Boolean,
      required: false,
      default: true,
    },
    showDeleteButton: {
      type: Boolean,
      required: false,
      default: true,
    },
    enableAutocomplete: {
      type: Boolean,
      required: false,
      default: true,
    },
    zoomMeetingUrl: {
      type: String,
      required: false,
      default: '',
    },
    publishedIncidentUrl: {
      type: String,
      required: false,
      default: '',
    },
    issuableRef: {
      type: String,
      required: true,
    },
    issuableStatus: {
      type: String,
      required: false,
      default: '',
    },
    initialTitleHtml: {
      type: String,
      required: true,
    },
    initialTitleText: {
      type: String,
      required: true,
    },
    initialDescriptionHtml: {
      type: String,
      required: false,
      default: '',
    },
    initialDescriptionText: {
      type: String,
      required: false,
      default: '',
    },
    initialTaskStatus: {
      type: String,
      required: false,
      default: '',
    },
    updatedAt: {
      type: String,
      required: false,
      default: '',
    },
    updatedByName: {
      type: String,
      required: false,
      default: '',
    },
    updatedByPath: {
      type: String,
      required: false,
      default: '',
    },
    issuableTemplateNamesPath: {
      type: String,
      required: false,
      default: '',
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
    markdownDocsPath: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    projectId: {
      type: Number,
      required: true,
    },
    projectNamespace: {
      type: String,
      required: true,
    },
    isConfidential: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLocked: {
      type: Boolean,
      required: false,
      default: false,
    },
    issuableType: {
      type: String,
      required: false,
      default: 'issue',
    },
    canAttachFile: {
      type: Boolean,
      required: false,
      default: true,
    },
    lockVersion: {
      type: Number,
      required: false,
      default: 0,
    },
    descriptionComponent: {
      type: Object,
      required: false,
      default: () => {
        return descriptionComponent;
      },
    },
    showTitleBorder: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    const store = new Store({
      titleHtml: this.initialTitleHtml,
      titleText: this.initialTitleText,
      descriptionHtml: this.initialDescriptionHtml,
      descriptionText: this.initialDescriptionText,
      updatedAt: this.updatedAt,
      updatedByName: this.updatedByName,
      updatedByPath: this.updatedByPath,
      taskStatus: this.initialTaskStatus,
      lock_version: this.lockVersion,
    });

    return {
      store,
      state: store.state,
      showForm: false,
      templatesRequested: false,
      isStickyHeaderShowing: false,
      issueState: {},
    };
  },
  apollo: {
    issueState: {
      query: getIssueStateQuery,
    },
  },
  computed: {
    issuableTemplates() {
      return this.store.formState.issuableTemplates;
    },
    formState() {
      return this.store.formState;
    },
    hasUpdated() {
      return Boolean(this.state.updatedAt);
    },
    issueChanged() {
      const {
        store: {
          formState: { description, title },
        },
        initialDescriptionText,
        initialTitleText,
      } = this;

      if (initialDescriptionText || description) {
        return initialDescriptionText !== description;
      }

      if (initialTitleText || title) {
        return initialTitleText !== title;
      }

      return false;
    },
    defaultErrorMessage() {
      return sprintf(s__('Error updating %{issuableType}'), { issuableType: this.issuableType });
    },
    isClosed() {
      return this.issuableStatus === IssuableStatus.Closed;
    },
    pinnedLinkClasses() {
      return this.showTitleBorder
        ? 'gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid gl-mb-6'
        : '';
    },
    statusIcon() {
      return this.isClosed ? 'issue-close' : 'issue-open-m';
    },
    statusText() {
      return IssuableStatusText[this.issuableStatus];
    },
    shouldShowStickyHeader() {
      return this.issuableType === IssuableType.Issue;
    },
  },
  created() {
    this.flashContainer = null;
    this.service = new Service(this.endpoint);
    this.poll = new Poll({
      resource: this.service,
      method: 'getData',
      successCallback: (res) => this.store.updateState(res.data),
      errorCallback(err) {
        throw new Error(err);
      },
    });

    if (!Visibility.hidden()) {
      this.poll.makeDelayedRequest(2000);
    }

    Visibility.change(() => {
      if (!Visibility.hidden()) {
        this.poll.restart();
      } else {
        this.poll.stop();
      }
    });

    window.addEventListener('beforeunload', this.handleBeforeUnloadEvent);

    eventHub.$on('delete.issuable', this.deleteIssuable);
    eventHub.$on('update.issuable', this.updateIssuable);
    eventHub.$on('close.form', this.closeForm);
    eventHub.$on('open.form', this.openForm);
  },
  beforeDestroy() {
    eventHub.$off('delete.issuable', this.deleteIssuable);
    eventHub.$off('update.issuable', this.updateIssuable);
    eventHub.$off('close.form', this.closeForm);
    eventHub.$off('open.form', this.openForm);
    window.removeEventListener('beforeunload', this.handleBeforeUnloadEvent);
  },
  methods: {
    handleBeforeUnloadEvent(e) {
      const event = e;
      if (this.showForm && this.issueChanged && !this.issueState.isDirty) {
        event.returnValue = __('Are you sure you want to lose your issue information?');
      }
      return undefined;
    },

    updateStoreState() {
      return this.service
        .getData()
        .then((res) => res.data)
        .then((data) => {
          this.store.updateState(data);
        })
        .catch(() => {
          createFlash({
            message: this.defaultErrorMessage,
          });
        });
    },

    updateAndShowForm(templates = {}) {
      if (!this.showForm) {
        this.showForm = true;
        this.store.setFormState({
          title: this.state.titleText,
          description: this.state.descriptionText,
          lock_version: this.state.lock_version,
          lockedWarningVisible: false,
          updateLoading: false,
          issuableTemplates: templates,
        });
      }
    },

    requestTemplatesAndShowForm() {
      return this.service
        .loadTemplates(this.issuableTemplateNamesPath)
        .then((res) => {
          this.updateAndShowForm(res.data);
        })
        .catch(() => {
          createFlash({
            message: this.defaultErrorMessage,
          });
          this.updateAndShowForm();
        });
    },

    openForm() {
      if (!this.templatesRequested) {
        this.templatesRequested = true;
        this.requestTemplatesAndShowForm();
      } else {
        this.updateAndShowForm(this.issuableTemplates);
      }
    },

    closeForm() {
      this.showForm = false;
    },

    updateIssuable() {
      const {
        store: { formState },
        issueState,
      } = this;
      const issuablePayload = issueState.isDirty
        ? { ...formState, issue_type: issueState.issueType }
        : formState;
      this.clearFlash();
      return this.service
        .updateIssuable(issuablePayload)
        .then((res) => res.data)
        .then((data) => {
          if (
            !window.location.pathname.includes(data.web_url) &&
            issueState.issueType !== IncidentType
          ) {
            visitUrl(data.web_url);
          }

          if (issueState.isDirty) {
            const URI =
              issueState.issueType === IncidentType
                ? data.web_url.replace(IssueTypePath, IncidentTypePath)
                : data.web_url;
            visitUrl(URI);
          }
        })
        .then(this.updateStoreState)
        .then(() => {
          eventHub.$emit('close.form');
        })
        .catch((error = {}) => {
          const { message, response = {} } = error;

          this.store.setFormState({
            updateLoading: false,
          });

          let errMsg = this.defaultErrorMessage;

          if (response.data && response.data.errors) {
            errMsg += `. ${response.data.errors.join(' ')}`;
          } else if (message) {
            errMsg += `. ${message}`;
          }

          this.flashContainer = createFlash({
            message: errMsg,
          });
        });
    },

    deleteIssuable(payload) {
      return this.service
        .deleteIssuable(payload)
        .then((res) => res.data)
        .then((data) => {
          // Stop the poll so we don't get 404's with the issuable not existing
          this.poll.stop();

          visitUrl(data.web_url);
        })
        .catch(() => {
          createFlash({
            message: sprintf(s__('Error deleting %{issuableType}'), {
              issuableType: this.issuableType,
            }),
          });
        });
    },

    hideStickyHeader() {
      this.isStickyHeaderShowing = false;
    },

    showStickyHeader() {
      this.isStickyHeaderShowing = true;
    },

    clearFlash() {
      if (this.flashContainer) {
        this.flashContainer.style.display = 'none';
        this.flashContainer = null;
      }
    },
  },
};
</script>

<template>
  <div>
    <div v-if="canUpdate && showForm">
      <form-component
        :form-state="formState"
        :initial-description-text="initialDescriptionText"
        :can-destroy="canDestroy"
        :issuable-templates="issuableTemplates"
        :markdown-docs-path="markdownDocsPath"
        :markdown-preview-path="markdownPreviewPath"
        :project-path="projectPath"
        :project-id="projectId"
        :project-namespace="projectNamespace"
        :show-delete-button="showDeleteButton"
        :can-attach-file="canAttachFile"
        :enable-autocomplete="enableAutocomplete"
        :issuable-type="issuableType"
      />
    </div>
    <div v-else>
      <title-component
        :issuable-ref="issuableRef"
        :can-update="canUpdate"
        :title-html="state.titleHtml"
        :title-text="state.titleText"
        :show-inline-edit-button="showInlineEditButton"
      />

      <gl-intersection-observer
        v-if="shouldShowStickyHeader"
        @appear="hideStickyHeader"
        @disappear="showStickyHeader"
      >
        <transition name="issuable-header-slide">
          <div
            v-if="isStickyHeaderShowing"
            class="issue-sticky-header gl-fixed gl-z-index-3 gl-bg-white gl-border-1 gl-border-b-solid gl-border-b-gray-100 gl-py-3"
            data-testid="issue-sticky-header"
          >
            <div
              class="issue-sticky-header-text gl-display-flex gl-align-items-center gl-mx-auto gl-px-5"
            >
              <p
                class="issuable-status-box status-box gl-my-0"
                :class="[isClosed ? 'status-box-issue-closed' : 'status-box-open']"
              >
                <gl-icon :name="statusIcon" class="gl-display-block d-sm-none gl-h-6!" />
                <span class="gl-display-none d-sm-block">{{ statusText }}</span>
              </p>
              <span v-if="isLocked" data-testid="locked" class="issuable-warning-icon">
                <gl-icon name="lock" :aria-label="__('Locked')" />
              </span>
              <span v-if="isConfidential" data-testid="confidential" class="issuable-warning-icon">
                <gl-icon name="eye-slash" :aria-label="__('Confidential')" />
              </span>
              <p
                class="gl-font-weight-bold gl-overflow-hidden gl-white-space-nowrap gl-text-overflow-ellipsis gl-my-0"
                :title="state.titleText"
              >
                {{ state.titleText }}
              </p>
            </div>
          </div>
        </transition>
      </gl-intersection-observer>

      <pinned-links
        :zoom-meeting-url="zoomMeetingUrl"
        :published-incident-url="publishedIncidentUrl"
        :class="pinnedLinkClasses"
      />

      <component
        :is="descriptionComponent"
        :can-update="canUpdate"
        :description-html="state.descriptionHtml"
        :description-text="state.descriptionText"
        :updated-at="state.updatedAt"
        :task-status="state.taskStatus"
        :issuable-type="issuableType"
        :update-url="updateEndpoint"
        :lock-version="state.lock_version"
        @taskListUpdateFailed="updateStoreState"
      />

      <edited-component
        v-if="hasUpdated"
        :updated-at="state.updatedAt"
        :updated-by-name="state.updatedByName"
        :updated-by-path="state.updatedByPath"
      />
    </div>
  </div>
</template>
