<script>
import { GlIcon, GlBadge, GlIntersectionObserver, GlTooltipDirective } from '@gitlab/ui';
import Visibility from 'visibilityjs';
import { createAlert } from '~/alert';
import {
  issuableStatusText,
  STATUS_CLOSED,
  TYPE_EPIC,
  TYPE_INCIDENT,
  TYPE_ISSUE,
  WORKSPACE_PROJECT,
} from '~/issues/constants';
import Poll from '~/lib/utils/poll';
import { visitUrl } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import ConfidentialityBadge from '~/vue_shared/components/confidentiality_badge.vue';
import { containsSensitiveToken, confirmSensitiveAction, i18n } from '~/lib/utils/secret_detection';
import { ISSUE_TYPE_PATH, INCIDENT_TYPE_PATH, POLLING_DELAY } from '../constants';
import eventHub from '../event_hub';
import getIssueStateQuery from '../queries/get_issue_state.query.graphql';
import Service from '../services/index';
import Store from '../stores';
import DescriptionComponent from './description.vue';
import EditedComponent from './edited.vue';
import FormComponent from './form.vue';
import PinnedLinks from './pinned_links.vue';
import TitleComponent from './title.vue';

export default {
  WORKSPACE_PROJECT,
  components: {
    GlIcon,
    GlBadge,
    GlIntersectionObserver,
    TitleComponent,
    EditedComponent,
    FormComponent,
    PinnedLinks,
    ConfidentialityBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
    initialTaskCompletionStatus: {
      type: Object,
      required: false,
      default: () => ({}),
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
      default: TYPE_ISSUE,
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
        return DescriptionComponent;
      },
    },
    showTitleBorder: {
      type: Boolean,
      required: false,
      default: true,
    },
    isHidden: {
      type: Boolean,
      required: false,
      default: false,
    },
    issueId: {
      type: Number,
      required: false,
      default: null,
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
      taskCompletionStatus: this.initialTaskCompletionStatus,
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
      return sprintf(__('Error updating %{issuableType}'), { issuableType: this.issuableType });
    },
    isClosed() {
      return this.issuableStatus === STATUS_CLOSED;
    },
    pinnedLinkClasses() {
      return this.showTitleBorder
        ? 'gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid gl-mb-6'
        : '';
    },
    statusIcon() {
      if (this.issuableType === TYPE_ISSUE) {
        return this.isClosed ? 'issue-closed' : 'issues';
      }
      return this.isClosed ? 'epic-closed' : 'epic';
    },
    statusVariant() {
      return this.isClosed ? 'info' : 'success';
    },
    statusText() {
      return issuableStatusText[this.issuableStatus];
    },
    shouldShowStickyHeader() {
      return [TYPE_ISSUE, TYPE_EPIC].includes(this.issuableType);
    },
  },
  created() {
    this.alert = null;
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
      this.poll.makeDelayedRequest(POLLING_DELAY);
    }

    Visibility.change(() => {
      if (!Visibility.hidden()) {
        this.poll.restart();
      } else {
        this.poll.stop();
      }
    });

    window.addEventListener('beforeunload', this.handleBeforeUnloadEvent);

    eventHub.$on('update.issuable', this.updateIssuable);
    eventHub.$on('close.form', this.closeForm);
    eventHub.$on('open.form', this.openForm);
  },
  beforeDestroy() {
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
          createAlert({
            message: this.defaultErrorMessage,
          });
        });
    },

    setFormState(state) {
      this.store.setFormState(state);
    },

    updateFormState(templates = {}) {
      this.setFormState({
        title: this.state.titleText,
        description: this.state.descriptionText,
        lock_version: this.state.lock_version,
        lockedWarningVisible: false,
        updateLoading: false,
        issuableTemplates: templates,
      });
    },

    updateAndShowForm(templates) {
      if (!this.showForm) {
        this.updateFormState(templates);
        this.showForm = true;
      }
    },

    requestTemplatesAndShowForm() {
      return this.service
        .loadTemplates(this.issuableTemplateNamesPath)
        .then((res) => {
          this.updateAndShowForm(res.data);
        })
        .catch(() => {
          createAlert({
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

    async updateIssuable() {
      this.setFormState({ updateLoading: true });

      const {
        store: { formState },
        issueState,
      } = this;
      const issuablePayload = issueState.isDirty
        ? { ...formState, issue_type: issueState.issueType }
        : formState;

      this.alert?.dismiss();

      if (containsSensitiveToken(issuablePayload.description)) {
        const confirmed = await confirmSensitiveAction(i18n.descriptionPrompt);
        if (!confirmed) {
          this.setFormState({ updateLoading: false });
          return false;
        }
      }

      return this.service
        .updateIssuable(issuablePayload)
        .then((res) => res.data)
        .then((data) => {
          if (
            !window.location.pathname.includes(data.web_url) &&
            issueState.issueType !== TYPE_INCIDENT
          ) {
            visitUrl(data.web_url);
          }

          if (issueState.isDirty) {
            const URI =
              issueState.issueType === TYPE_INCIDENT
                ? data.web_url.replace(ISSUE_TYPE_PATH, INCIDENT_TYPE_PATH)
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

          let errMsg = this.defaultErrorMessage;

          if (response.data && response.data.errors) {
            errMsg += `. ${response.data.errors.join(' ')}`;
          } else if (message) {
            errMsg += `. ${message}`;
          }

          this.alert = createAlert({
            message: errMsg,
          });
        })
        .finally(() => {
          this.setFormState({ updateLoading: false });
        });
    },

    hideStickyHeader() {
      this.isStickyHeaderShowing = false;
    },

    showStickyHeader() {
      this.isStickyHeaderShowing = true;
    },

    handleSaveDescription(description) {
      this.updateFormState();
      this.setFormState({ description });
      this.updateIssuable();
    },

    taskListUpdateStarted() {
      this.poll.stop();
    },

    taskListUpdateSucceeded() {
      this.poll.enable();
      this.poll.makeDelayedRequest(POLLING_DELAY);
    },

    taskListUpdateFailed() {
      this.poll.enable();
      this.poll.makeDelayedRequest(POLLING_DELAY);

      this.updateStoreState();
    },
  },
};
</script>

<template>
  <div>
    <div v-if="canUpdate && showForm">
      <form-component
        :endpoint="endpoint"
        :form-state="formState"
        :initial-description-text="initialDescriptionText"
        :issuable-templates="issuableTemplates"
        :markdown-docs-path="markdownDocsPath"
        :markdown-preview-path="markdownPreviewPath"
        :project-path="projectPath"
        :project-id="projectId"
        :project-namespace="projectNamespace"
        :can-attach-file="canAttachFile"
        :enable-autocomplete="enableAutocomplete"
        :issuable-type="issuableType"
        @updateForm="setFormState"
      />
    </div>
    <div v-else>
      <title-component
        :issuable-ref="issuableRef"
        :can-update="canUpdate"
        :title-html="state.titleHtml"
        :title-text="state.titleText"
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
              <gl-badge :variant="statusVariant" class="gl-mr-2">
                <gl-icon :name="statusIcon" />
                <span class="gl-display-none gl-sm-display-block gl-ml-2">{{
                  statusText
                }}</span></gl-badge
              >
              <span v-if="isLocked" data-testid="locked" class="issuable-warning-icon">
                <gl-icon name="lock" :aria-label="__('Locked')" />
              </span>
              <confidentiality-badge
                v-if="isConfidential"
                data-testid="confidential"
                :workspace-type="$options.WORKSPACE_PROJECT"
                :issuable-type="issuableType"
              />
              <span
                v-if="isHidden"
                v-gl-tooltip
                :title="__('This issue is hidden because its author has been banned')"
                data-testid="hidden"
                class="issuable-warning-icon"
              >
                <gl-icon name="spam" />
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
        :issue-id="issueId"
        :can-update="canUpdate"
        :description-html="state.descriptionHtml"
        :description-text="state.descriptionText"
        :updated-at="state.updatedAt"
        :issuable-type="issuableType"
        :update-url="updateEndpoint"
        :lock-version="state.lock_version"
        :is-updating="formState.updateLoading"
        @saveDescription="handleSaveDescription"
        @taskListUpdateStarted="taskListUpdateStarted"
        @taskListUpdateSucceeded="taskListUpdateSucceeded"
        @taskListUpdateFailed="taskListUpdateFailed"
        @updateDescription="state.descriptionHtml = $event"
      />

      <edited-component
        :task-completion-status="state.taskCompletionStatus"
        :updated-at="state.updatedAt"
        :updated-by-name="state.updatedByName"
        :updated-by-path="state.updatedByPath"
      />
    </div>
  </div>
</template>
