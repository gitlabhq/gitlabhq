<script>
import Visibility from 'visibilityjs';
import { createAlert } from '~/alert';
import { TYPE_EPIC, TYPE_INCIDENT, TYPE_ISSUE } from '~/issues/constants';
import updateDescription from '~/issues/show/utils/update_description';
import { sanitize } from '~/lib/dompurify';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import Poll from '~/lib/utils/poll';
import { detectAndConfirmSensitiveTokens, CONTENT_TYPE } from '~/lib/utils/secret_detection';
import { visitUrl } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import { ISSUE_TYPE_PATH, INCIDENT_TYPE_PATH, POLLING_DELAY } from '../constants';
import eventHub from '../event_hub';
import getIssueStateQuery from '../queries/get_issue_state.query.graphql';
import Service from '../services/index';
import DescriptionComponent from './description.vue';
import EditedComponent from './edited.vue';
import FormComponent from './form.vue';
import HeaderActions from './header_actions.vue';
import IssueHeader from './issue_header.vue';
import PinnedLinks from './pinned_links.vue';
import StickyHeader from './sticky_header.vue';
import TitleComponent from './title.vue';

const STICKY_HEADER_VISIBLE_CLASS = 'issuable-sticky-header-visible';

function stripClientState(html) {
  // remove all attributes of details tags
  return html.replace(/<details[^>]*>/g, '<details>');
}

function hasDescriptionChanged(oldDesc, newDesc) {
  return stripClientState(oldDesc) !== stripClientState(newDesc);
}

export default {
  components: {
    HeaderActions,
    IssueHeader,
    TitleComponent,
    EditedComponent,
    FormComponent,
    PinnedLinks,
    StickyHeader,
  },
  props: {
    author: {
      type: Object,
      required: false,
      default: () => ({}),
    },
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
    createdAt: {
      type: String,
      required: false,
      default: '',
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
    isImported: {
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
      type: String,
      required: false,
      default: null,
    },
    issueIid: {
      type: String,
      required: false,
      default: null,
    },
    duplicatedToIssueUrl: {
      type: String,
      required: false,
      default: '',
    },
    movedToIssueUrl: {
      type: String,
      required: false,
      default: '',
    },
    promotedToEpicUrl: {
      type: String,
      required: false,
      default: '',
    },
    isFirstContribution: {
      type: Boolean,
      required: false,
      default: false,
    },
    serviceDeskReplyTo: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      formState: {
        title: '',
        description: '',
        lockedWarningVisible: false,
        updateLoading: false,
        lock_version: 0,
        issuableTemplates: {},
      },
      state: {
        titleHtml: this.initialTitleHtml,
        titleText: this.initialTitleText,
        descriptionHtml: this.initialDescriptionHtml,
        descriptionText: this.initialDescriptionText,
        updatedAt: this.updatedAt,
        updatedByName: this.updatedByName,
        updatedByPath: this.updatedByPath,
        taskCompletionStatus: this.initialTaskCompletionStatus,
        lock_version: this.lockVersion,
      },
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
    headerClasses() {
      return this.issuableType === TYPE_INCIDENT ? 'gl-mb-3' : 'gl-mb-6';
    },
    issueChanged() {
      const {
        formState: { description, title },
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

    pinnedLinkClasses() {
      return this.showTitleBorder
        ? 'gl-border-b-1 gl-border-b-default gl-border-b-solid gl-mb-6'
        : '';
    },

    shouldShowStickyHeader() {
      return [TYPE_INCIDENT, TYPE_ISSUE, TYPE_EPIC].includes(this.issuableType);
    },
  },
  created() {
    this.alert = null;
    this.service = new Service(this.endpoint);
    this.poll = new Poll({
      resource: this.service,
      method: 'getData',
      successCallback: (res) => this.updateState(res.data),
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
    this.hideStickyHeader();
  },
  methods: {
    handleBeforeUnloadEvent(e) {
      const event = e;
      if (this.showForm && this.issueChanged && !this.issueState.isDirty) {
        event.returnValue = __('Are you sure you want to lose your issue information?');
      }
      return undefined;
    },
    updateState(data) {
      const stateShouldUpdate =
        this.state.titleText !== data.title_text ||
        this.state.descriptionText !== data.description_text;

      if (stateShouldUpdate) {
        this.formState.lockedWarningVisible = true;
      }

      Object.assign(this.state, convertObjectPropsToCamelCase(data));
      // find if there is an open details node inside of the issue description.
      const descriptionSection = document.body.querySelector(
        '.detail-page-description.content-block',
      );
      const details =
        descriptionSection != null && descriptionSection.getElementsByTagName('details');

      const newDescriptionHtml = updateDescription(sanitize(data.description), details);

      if (hasDescriptionChanged(this.state.descriptionHtml, newDescriptionHtml)) {
        this.state.descriptionHtml = newDescriptionHtml;
      }

      this.state.titleHtml = sanitize(data.title);
      this.state.lock_version = data.lock_version;
    },
    refetchData() {
      return this.service
        .getData()
        .then((res) => res.data)
        .then(this.updateState)
        .catch(() => createAlert({ message: this.defaultErrorMessage }));
    },

    setFormState(state) {
      this.formState = { ...this.formState, ...state };
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
        this.updateAndShowForm(this.formState.issuableTemplates);
      }
    },

    closeForm() {
      this.showForm = false;
    },

    async updateIssuable() {
      this.setFormState({ updateLoading: true });

      const { formState, issueState } = this;
      const issuablePayload = issueState.isDirty
        ? { ...formState, issue_type: issueState.issueType }
        : formState;

      this.alert?.dismiss();

      const confirmSubmit = await detectAndConfirmSensitiveTokens({
        content: issuablePayload.description,
        contentType: CONTENT_TYPE.DESCRIPTION,
      });

      if (!confirmSubmit) {
        this.setFormState({ updateLoading: false });
        return false;
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
        .then(this.refetchData)
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

      document.body.classList?.remove(STICKY_HEADER_VISIBLE_CLASS);
    },

    showStickyHeader() {
      // only if scrolled under the issue's title
      if (this.$refs.title.$el.offsetTop < window.pageYOffset) {
        this.isStickyHeaderShowing = true;
      }

      document.body.classList?.add(STICKY_HEADER_VISIBLE_CLASS);
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

      this.refetchData();
    },
  },
};
</script>

<template>
  <div>
    <div v-if="canUpdate && showForm">
      <h1 class="gl-sr-only">{{ __('Edit issue') }}</h1>
      <form-component
        :endpoint="endpoint"
        :form-state="formState"
        :initial-description-text="initialDescriptionText"
        :issuable-templates="formState.issuableTemplates"
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
        ref="title"
        :issuable-ref="issuableRef"
        :can-update="canUpdate"
        :title-html="state.titleHtml"
        :title-text="state.titleText"
      >
        <template #actions>
          <slot name="actions">
            <header-actions />
          </slot>
        </template>
      </title-component>

      <sticky-header
        v-if="shouldShowStickyHeader"
        :is-confidential="isConfidential"
        :is-hidden="isHidden"
        :is-imported="isImported"
        :is-locked="isLocked"
        :issuable-state="issuableStatus"
        :issuable-type="issuableType"
        :show="isStickyHeaderShowing"
        :title="state.titleText"
        :duplicated-to-issue-url="duplicatedToIssueUrl"
        :moved-to-issue-url="movedToIssueUrl"
        :promoted-to-epic-url="promotedToEpicUrl"
        @hide="hideStickyHeader"
        @show="showStickyHeader"
      />

      <slot name="header">
        <issue-header
          class="gl-mt-2 gl-p-0"
          :class="headerClasses"
          :author="author"
          :confidential="isConfidential"
          :created-at="createdAt"
          :duplicated-to-issue-url="duplicatedToIssueUrl"
          :is-first-contribution="isFirstContribution"
          :is-hidden="isHidden"
          :is-imported="isImported"
          :is-locked="isLocked"
          :issuable-state="issuableStatus"
          :issuable-type="issuableType"
          :moved-to-issue-url="movedToIssueUrl"
          :promoted-to-epic-url="promotedToEpicUrl"
          :service-desk-reply-to="serviceDeskReplyTo"
        />
      </slot>

      <pinned-links
        :zoom-meeting-url="zoomMeetingUrl"
        :published-incident-url="publishedIncidentUrl"
        :class="pinnedLinkClasses"
      />

      <component
        :is="descriptionComponent"
        :issue-id="issueId"
        :issue-iid="issueIid"
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
        class="gl-mt-4"
        :task-completion-status="state.taskCompletionStatus"
        :updated-at="state.updatedAt"
        :updated-by-name="state.updatedByName"
        :updated-by-path="state.updatedByPath"
      />
    </div>
  </div>
</template>
