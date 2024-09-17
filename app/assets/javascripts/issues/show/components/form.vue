<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlAlert } from '@gitlab/ui';
import { getDraft, updateDraft, getLockVersion, clearDraft } from '~/lib/utils/autosave';
import { TYPE_INCIDENT, TYPE_ISSUE } from '~/issues/constants';
import eventHub from '../event_hub';
import EditActions from './edit_actions.vue';
import DescriptionField from './fields/description.vue';
import DescriptionTemplateField from './fields/description_template.vue';
import IssuableTitleField from './fields/title.vue';
import IssuableTypeField from './fields/type.vue';
import LockedWarning from './locked_warning.vue';

export default {
  components: {
    DescriptionField,
    DescriptionTemplateField,
    EditActions,
    GlAlert,
    IssuableTitleField,
    IssuableTypeField,
    LockedWarning,
  },
  props: {
    endpoint: {
      type: String,
      required: true,
    },
    formState: {
      type: Object,
      required: true,
    },
    issuableTemplates: {
      type: [Object, Array],
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
    projectId: {
      type: Number,
      required: true,
    },
    projectNamespace: {
      type: String,
      required: true,
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
    const autosaveKey = [document.location.pathname, document.location.search];
    const descriptionAutosaveKey = [...autosaveKey, 'description'];
    const titleAutosaveKey = [...autosaveKey, 'title'];

    return {
      titleAutosaveKey,
      descriptionAutosaveKey,
      autosaveReset: false,
      formData: {
        title: getDraft(titleAutosaveKey) || this.formState.title,
        description: getDraft(descriptionAutosaveKey) || this.formState.description,
      },
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
    showTypeField() {
      return [TYPE_INCIDENT, TYPE_ISSUE].includes(this.issuableType);
    },
  },
  watch: {
    formData: {
      handler(value) {
        this.$emit('updateForm', value);
      },
      deep: true,
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
      const savedLockVersion = getLockVersion(this.descriptionAutosaveKey);

      this.showOutdatedDescriptionWarning =
        savedLockVersion && String(this.formState.lock_version) !== savedLockVersion;
    },
    resetAutosave() {
      this.autosaveReset = true;
      clearDraft(this.descriptionAutosaveKey);
      clearDraft(this.titleAutosaveKey);
    },
    keepAutosave() {
      this.$refs.description.focus();
      this.showOutdatedDescriptionWarning = false;
    },
    discardAutosave() {
      this.formData.description = this.initialDescriptionText;
      clearDraft(this.descriptionAutosaveKey);
      this.$refs.description.focus();
      this.showOutdatedDescriptionWarning = false;
    },
    updateTitleDraft(title) {
      updateDraft(this.titleAutosaveKey, title);
    },
    updateDescriptionDraft(description) {
      /*
       * This conditional statement prevents a race-condition
       * between clearing the draft and submitting a new draft
       * update while the user is typing. It happens when saving
       * using the cmd + enter keyboard shortcut.
       */
      if (!this.autosaveReset) {
        updateDraft(this.descriptionAutosaveKey, description, this.formState.lock_version);
      }
    },
  },
};
</script>

<template>
  <form data-testid="issuable-form" class="gl-mt-1">
    <locked-warning v-if="showLockedWarning" :issuable-type="issuableType" />
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
    <div class="row gl-mb-3">
      <div class="col-12">
        <issuable-title-field ref="title" v-model="formData.title" @input="updateTitleDraft" />
      </div>
    </div>
    <div class="row gl-gap-3">
      <div v-if="showTypeField" class="col-12 col-md-4 pr-md-0">
        <issuable-type-field ref="issue-type" />
      </div>

      <div v-if="hasIssuableTemplates" class="col-12 col-md-4 md:gl-pl-0 md:gl-pr-0">
        <description-template-field
          v-model="formData.description"
          :issuable-templates="issuableTemplates"
          :project-path="projectPath"
          :project-id="projectId"
          :project-namespace="projectNamespace"
        />
      </div>
    </div>

    <description-field
      ref="description"
      v-model="formData.description"
      :markdown-preview-path="markdownPreviewPath"
      :markdown-docs-path="markdownDocsPath"
      :can-attach-file="canAttachFile"
      :enable-autocomplete="enableAutocomplete"
      @input="updateDescriptionDraft"
    />

    <edit-actions :endpoint="endpoint" :form-state="formState" :issuable-type="issuableType" />
  </form>
</template>
