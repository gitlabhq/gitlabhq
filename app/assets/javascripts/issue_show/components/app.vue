<script>
import Visibility from 'visibilityjs';
import Poll from '../../lib/utils/poll';
import eventHub from '../event_hub';
import Service from '../services/index';
import Store from '../stores';
import titleComponent from './title.vue';
import descriptionComponent from './description.vue';
import editedComponent from './edited.vue';
import formComponent from './form.vue';
import '../../lib/utils/url_utility';

export default {
  props: {
    endpoint: {
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
      default: false,
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
    issuableTemplates: {
      type: Array,
      required: false,
      default: () => [],
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
    });

    return {
      store,
      state: store.state,
      showForm: false,
    };
  },
  computed: {
    formState() {
      return this.store.formState;
    },
    hasUpdated() {
      return !!this.state.updatedAt;
    },
  },
  components: {
    descriptionComponent,
    titleComponent,
    editedComponent,
    formComponent,
  },
  methods: {
    openForm() {
      if (!this.showForm) {
        this.showForm = true;
        this.store.setFormState({
          title: this.state.titleText,
          description: this.state.descriptionText,
          lockedWarningVisible: false,
          updateLoading: false,
        });
      }
    },
    closeForm() {
      this.showForm = false;
    },
    updateIssuable() {
      this.service.updateIssuable(this.store.formState)
        .then(res => res.json())
        .then((data) => {
          if (location.pathname !== data.web_url) {
            gl.utils.visitUrl(data.web_url);
          }

          return this.service.getData();
        })
        .then(res => res.json())
        .then((data) => {
          this.store.updateState(data);
          eventHub.$emit('close.form');
        })
        .catch(() => {
          eventHub.$emit('close.form');
          window.Flash(`Error updating ${this.issuableType}`);
        });
    },
    deleteIssuable() {
      this.service.deleteIssuable()
        .then(res => res.json())
        .then((data) => {
          // Stop the poll so we don't get 404's with the issuable not existing
          this.poll.stop();

          gl.utils.visitUrl(data.web_url);
        })
        .catch(() => {
          eventHub.$emit('close.form');
          window.Flash(`Error deleting ${this.issuableType}`);
        });
    },
  },
  created() {
    this.service = new Service(this.endpoint);
    this.poll = new Poll({
      resource: this.service,
      method: 'getData',
      successCallback: res => res.json().then(data => this.store.updateState(data)),
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
  },
};
</script>

<template>
  <div>
    <form-component
      v-if="canUpdate && showForm"
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
    />
    <div v-else>
      <title-component
        :issuable-ref="issuableRef"
        :can-update="canUpdate"
        :title-html="state.titleHtml"
        :title-text="state.titleText"
        :show-inline-edit-button="showInlineEditButton"
      />
      <description-component
        v-if="state.descriptionHtml"
        :can-update="canUpdate"
        :description-html="state.descriptionHtml"
        :description-text="state.descriptionText"
        :updated-at="state.updatedAt"
        :task-status="state.taskStatus"
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
