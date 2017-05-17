<script>
/* global Flash */
import Visibility from 'visibilityjs';
import Poll from '../../lib/utils/poll';
import eventHub from '../event_hub';
import Service from '../services/index';
import Store from '../stores';
import titleComponent from './title.vue';
import descriptionComponent from './description.vue';
import formComponent from './form.vue';

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
    issuableRef: {
      type: String,
      required: true,
    },
    initialTitle: {
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
  },
  data() {
    const store = new Store({
      titleHtml: this.initialTitle,
      descriptionHtml: this.initialDescriptionHtml,
      descriptionText: this.initialDescriptionText,
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
  },
  components: {
    descriptionComponent,
    titleComponent,
    formComponent,
  },
  methods: {
    openForm() {
      this.showForm = true;
      this.store.formState = {
        title: this.state.titleText,
        confidential: this.isConfidential,
        description: this.state.descriptionText,
      };
    },
    closeForm() {
      this.showForm = false;
    },
    updateIssuable() {
      this.service.updateIssuable(this.store.formState)
        .then((res) => {
          const data = res.json();

          if (data.confidential !== this.isConfidential) {
            location.reload();
          }

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

          gl.utils.visitUrl(data.path);
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
      successCallback: (res) => {
        this.store.updateState(res.json());
      },
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
      :markdown-docs="markdownDocs"
      :markdown-preview-url="markdownPreviewUrl"
      :project-path="projectPath"
      :project-namespace="projectNamespace" />
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
    </div>
  </div>
</template>
