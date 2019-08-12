<script>
import $ from 'jquery';
import lockedWarning from './locked_warning.vue';
import titleField from './fields/title.vue';
import descriptionField from './fields/description.vue';
import editActions from './edit_actions.vue';
import descriptionTemplate from './fields/description_template.vue';
import Autosave from '~/autosave';
import eventHub from '../event_hub';

export default {
  components: {
    lockedWarning,
    titleField,
    descriptionField,
    descriptionTemplate,
    editActions,
  },
  props: {
    canDestroy: {
      type: Boolean,
      required: true,
    },
    formState: {
      type: Object,
      required: true,
    },
    issuableTemplates: {
      type: Array,
      required: false,
      default: () => [],
    },
    issuableType: {
      type: String,
      required: true,
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
    showDeleteButton: {
      type: Boolean,
      required: false,
      default: true,
    },
    canAttachFile: {
      type: Boolean,
      required: false,
      default: true,
    },
    enableAutocomplete: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  computed: {
    hasIssuableTemplates() {
      return this.issuableTemplates.length;
    },
    showLockedWarning() {
      return this.formState.lockedWarningVisible && !this.formState.updateLoading;
    },
  },
  created() {
    eventHub.$on('delete.issuable', this.resetAutosave);
    eventHub.$on('update.issuable', this.resetAutosave);
    eventHub.$on('close.form', this.resetAutosave);
  },
  mounted() {
    this.initAutosave();
  },
  beforeDestroy() {
    eventHub.$off('delete.issuable', this.resetAutosave);
    eventHub.$off('update.issuable', this.resetAutosave);
    eventHub.$off('close.form', this.resetAutosave);
  },
  methods: {
    initAutosave() {
      const {
        description: {
          $refs: { textarea },
        },
        title: {
          $refs: { input },
        },
      } = this.$refs;

      this.autosaveDescription = new Autosave($(textarea), [
        document.location.pathname,
        document.location.search,
        'description',
      ]);

      this.autosaveTitle = new Autosave($(input), [
        document.location.pathname,
        document.location.search,
        'title',
      ]);
    },
    resetAutosave() {
      this.autosaveDescription.reset();
      this.autosaveTitle.reset();
    },
  },
};
</script>

<template>
  <form>
    <locked-warning v-if="showLockedWarning" />
    <div class="row">
      <div v-if="hasIssuableTemplates" class="col-sm-4 col-lg-3">
        <description-template
          :form-state="formState"
          :issuable-templates="issuableTemplates"
          :project-path="projectPath"
          :project-namespace="projectNamespace"
        />
      </div>
      <div
        :class="{
          'col-sm-8 col-lg-9': hasIssuableTemplates,
          'col-12': !hasIssuableTemplates,
        }"
      >
        <title-field ref="title" :form-state="formState" :issuable-templates="issuableTemplates" />
      </div>
    </div>
    <description-field
      ref="description"
      :form-state="formState"
      :markdown-preview-path="markdownPreviewPath"
      :markdown-docs-path="markdownDocsPath"
      :can-attach-file="canAttachFile"
      :enable-autocomplete="enableAutocomplete"
    />
    <edit-actions
      :form-state="formState"
      :can-destroy="canDestroy"
      :show-delete-button="showDeleteButton"
      :issuable-type="issuableType"
    />
  </form>
</template>
