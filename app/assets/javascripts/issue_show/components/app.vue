<script>
import Visibility from 'visibilityjs';
import { __, s__, sprintf } from '~/locale';
import createFlash from '~/flash';
import { visitUrl } from '../../lib/utils/url_utility';
import Poll from '../../lib/utils/poll';
import eventHub from '../event_hub';
import Service from '../services/index';
import Store from '../stores';
import titleComponent from './title.vue';
import descriptionComponent from './description.vue';
import editedComponent from './edited.vue';
import formComponent from './form.vue';
import PinnedLinks from './pinned_links.vue';
import recaptchaModalImplementor from '../../vue_shared/mixins/recaptcha_modal_implementor';

export default {
  components: {
    descriptionComponent,
    titleComponent,
    editedComponent,
    formComponent,
    PinnedLinks,
  },
  mixins: [recaptchaModalImplementor],
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
    projectNamespace: {
      type: String,
      required: true,
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
    };
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
  },
  created() {
    this.service = new Service(this.endpoint);
    this.poll = new Poll({
      resource: this.service,
      method: 'getData',
      successCallback: res => this.store.updateState(res.data),
      errorCallback(err) {
        throw new Error(err);
      },
    });

    if (!Visibility.hidden()) {
      this.poll.makeRequest();
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
      if (this.showForm && this.issueChanged && !this.showRecaptcha) {
        event.returnValue = __('Are you sure you want to lose your issue information?');
      }
      return undefined;
    },

    updateStoreState() {
      return this.service
        .getData()
        .then(res => res.data)
        .then(data => {
          this.store.updateState(data);
        })
        .catch(() => {
          createFlash(this.defaultErrorMessage);
        });
    },

    updateAndShowForm(templates = []) {
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
        .then(res => {
          this.updateAndShowForm(res.data);
        })
        .catch(() => {
          createFlash(this.defaultErrorMessage);
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
      return this.service
        .updateIssuable(this.store.formState)
        .then(res => res.data)
        .then(data => this.checkForSpam(data))
        .then(data => {
          if (!window.location.pathname.includes(data.web_url)) {
            visitUrl(data.web_url);
          }
        })
        .then(this.updateStoreState)
        .then(() => {
          eventHub.$emit('close.form');
        })
        .catch((error = {}) => {
          const { name, response = {} } = error;

          if (name === 'SpamError') {
            this.openRecaptcha();
          } else {
            let errMsg = this.defaultErrorMessage;

            if (response.data && response.data.errors) {
              errMsg += `. ${response.data.errors.join(' ')}`;
            }

            createFlash(errMsg);
          }
        });
    },

    closeRecaptchaModal() {
      this.store.setFormState({
        updateLoading: false,
      });

      this.closeRecaptcha();
    },

    deleteIssuable(payload) {
      return this.service
        .deleteIssuable(payload)
        .then(res => res.data)
        .then(data => {
          // Stop the poll so we don't get 404's with the issuable not existing
          this.poll.stop();

          visitUrl(data.web_url);
        })
        .catch(() => {
          createFlash(
            sprintf(s__('Error deleting %{issuableType}'), { issuableType: this.issuableType }),
          );
        });
    },
  },
};
</script>

<template>
  <div>
    <div v-if="canUpdate && showForm">
      <form-component
        :form-state="formState"
        :can-destroy="canDestroy"
        :issuable-templates="issuableTemplates"
        :markdown-docs-path="markdownDocsPath"
        :markdown-preview-path="markdownPreviewPath"
        :project-path="projectPath"
        :project-namespace="projectNamespace"
        :show-delete-button="showDeleteButton"
        :can-attach-file="canAttachFile"
        :enable-autocomplete="enableAutocomplete"
        :issuable-type="issuableType"
      />

      <recaptcha-modal
        v-show="showRecaptcha"
        ref="recaptchaModal"
        :html="recaptchaHTML"
        @close="closeRecaptchaModal"
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
      <pinned-links
        :zoom-meeting-url="zoomMeetingUrl"
        :published-incident-url="publishedIncidentUrl"
      />
      <description-component
        v-if="state.descriptionHtml"
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
