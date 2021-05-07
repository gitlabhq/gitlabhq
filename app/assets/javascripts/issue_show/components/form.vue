<script>
import { GlAlert } from '@gitlab/ui';
import $ from 'jquery';
import Autosave from '~/autosave';
import eventHub from '../event_hub';
import editActions from './edit_actions.vue';
import descriptionField from './fields/description.vue';
import descriptionTemplate from './fields/description_template.vue';
import titleField from './fields/title.vue';
import lockedWarning from './locked_warning.vue';

export default {
  components: {
    lockedWarning,
    titleField,
    descriptionField,
    descriptionTemplate,
    editActions,
    GlAlert,
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
      type: [Object, Array],
      required: false,
      default: () => {},
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
    projectId: {
      type: Number,
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
    initialDescriptionText: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      showOutdatedDescriptionWarning: false,
    };
  },
  computed: {
    hasIssuableTemplates() {
      return Object.values(Object(this.issuableTemplates)).length;
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

      this.autosaveDescription = new Autosave(
        $(textarea),
        [document.location.pathname, document.location.search, 'description'],
        null,
        this.formState.lock_version,
      );

      const savedLockVersion = this.autosaveDescription.getSavedLockVersion();

      this.showOutdatedDescriptionWarning =
        savedLockVersion && String(this.formState.lock_version) !== savedLockVersion;

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
    keepAutosave() {
      const {
        description: {
          $refs: { textarea },
        },
      } = this.$refs;

      textarea.focus();
      this.showOutdatedDescriptionWarning = false;
    },
    discardAutosave() {
      const {
        description: {
          $refs: { textarea },
        },
      } = this.$refs;

      textarea.value = this.initialDescriptionText;
      textarea.focus();
      this.showOutdatedDescriptionWarning = false;
    },
  },
};
</script>

<template>
  <form>
    <locked-warning v-if="showLockedWarning" />
    <gl-alert
      v-if="showOutdatedDescriptionWarning"
      class="gl-mb-5"
      variant="warning"
      :primary-button-text="__('Keep')"
      :secondary-button-text="__('Discard')"
      :dismissible="false"
      @primaryAction="keepAutosave"
      @secondaryAction="discardAutosave"
      >{{
        __(
          'The comment you are editing has been changed by another user. Would you like to keep your changes and overwrite the new description or discard your changes?',
        )
      }}</gl-alert
    >
    <div class="row">
      <div v-if="hasIssuableTemplates" class="col-sm-4 col-lg-3">
        <description-template
          :form-state="formState"
          :issuable-templates="issuableTemplates"
          :project-path="projectPath"
          :project-id="projectId"
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
