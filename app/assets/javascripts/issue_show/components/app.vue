<script>
/* global Flash */
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
    canMove: {
      required: true,
      type: Boolean,
    },
    canUpdate: {
      required: true,
      type: Boolean,
    },
    canDestroy: {
      required: true,
      type: Boolean,
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
    isConfidential: {
      type: Boolean,
      required: true,
    },
    markdownPreviewUrl: {
      type: String,
      required: true,
    },
    markdownDocs: {
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
    projectsAutocompleteUrl: {
      type: String,
      required: true,
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
          confidential: this.isConfidential,
          description: this.state.descriptionText,
          lockedWarningVisible: false,
          move_to_project_id: 0,
          updateLoading: false,
        });
      }
    },
    closeForm() {
      this.showForm = false;
    },
    updateIssuable() {
      const canPostUpdate = this.store.formState.move_to_project_id !== 0 ?
        confirm('Are you sure you want to move this issue to another project?') : true; // eslint-disable-line no-alert

      if (!canPostUpdate) {
        this.store.setFormState({
          updateLoading: false,
        });
        return;
      }

      this.service.updateIssuable(this.store.formState)
        .then(res => res.json())
        .then((data) => {
          if (location.pathname !== data.web_url) {
            gl.utils.visitUrl(data.web_url);
          } else if (data.confidential !== this.isConfidential) {
            gl.utils.visitUrl(location.pathname);
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
          return new Flash('Error updating issue');
        });
    },
    deleteIssuable() {
      this.service.deleteIssuable()
        .then(res => res.json())
        .then((data) => {
          // Stop the poll so we don't get 404's with the issue not existing
          this.poll.stop();

          gl.utils.visitUrl(data.web_url);
        })
        .catch(() => {
          eventHub.$emit('close.form');
          return new Flash('Error deleting issue');
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
      :can-move="canMove"
      :can-destroy="canDestroy"
      :issuable-templates="issuableTemplates"
      :markdown-docs="markdownDocs"
      :markdown-preview-url="markdownPreviewUrl"
      :project-path="projectPath"
      :project-namespace="projectNamespace"
      :projects-autocomplete-url="projectsAutocompleteUrl"
    />
    <div v-else>
      <title-component
        :issuable-ref="issuableRef"
        :title-html="state.titleHtml"
        :title-text="state.titleText" />
      <description-component
        v-if="state.descriptionHtml"
        :can-update="canUpdate"
        :description-html="state.descriptionHtml"
        :description-text="state.descriptionText"
        :updated-at="state.updatedAt"
        :task-status="state.taskStatus" />
      <edited-component
        v-if="hasUpdated"
        :updated-at="state.updatedAt"
        :updated-by-name="state.updatedByName"
        :updated-by-path="state.updatedByPath" />
    </div>
  </div>
</template>
