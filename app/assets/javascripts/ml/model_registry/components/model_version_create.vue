<script>
import {
  GlAlert,
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlModal,
  GlModalDirective,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { semverRegex } from '~/lib/utils/regexp';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import createModelVersionMutation from '../graphql/mutations/create_model_version.mutation.graphql';
import { MODEL_VERSION_CREATION_MODAL_ID } from '../constants';

export default {
  name: 'ModelVersionCreate',
  components: {
    GlAlert,
    GlButton,
    GlModal,
    GlForm,
    GlFormGroup,
    GlFormInput,
    MarkdownEditor,
    ImportArtifactZone: () => import('./import_artifact_zone.vue'),
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: ['projectPath', 'maxAllowedFileSize', 'latestVersion', 'markdownPreviewPath'],
  props: {
    modelGid: {
      type: String,
      required: true,
    },
    disableAttachments: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      version: null,
      description: '',
      errorMessage: null,
      versionData: null,
      submitButtonDisabled: true,
      markdownDocPath: helpPagePath('user/markdown'),
      markdownEditorRestrictedToolBarItems: ['full-screen'],
    };
  },
  computed: {
    versionDescription() {
      if (this.latestVersion) {
        return sprintf(
          s__('MlModelRegistry|Enter a semantic version. Latest version is %{latestVersion}'),
          {
            latestVersion: this.latestVersion,
          },
        );
      }
      return s__('MlModelRegistry|Enter a semantic version.');
    },
    autocompleteDataSources() {
      return gl.GfmAutoComplete?.dataSources;
    },
    actionPrimary() {
      return {
        text: s__('MlModelRegistry|Create & import'),
        attributes: { variant: 'confirm', disabled: this.submitButtonDisabled },
      };
    },
    isSemver() {
      return semverRegex.test(this.version);
    },
    invalidFeedback() {
      if (this.version === null) {
        this.submitDisabled();
        return this.versionDescription;
      }
      if (!this.isSemver) {
        this.submitDisabled();
        return this.$options.modal.versionInvalid;
      }
      this.submitAvailable();
      return null;
    },
  },
  methods: {
    submitDisabled() {
      this.submitButtonDisabled = true;
    },
    submitAvailable() {
      this.submitButtonDisabled = false;
    },
    async createModelVersion() {
      const { data } = await this.$apollo.mutate({
        mutation: createModelVersionMutation,
        variables: {
          projectPath: this.projectPath,
          modelId: this.modelGid,
          version: this.version,
          description: this.description,
        },
      });

      return data;
    },
    async create($event) {
      $event.preventDefault();

      this.errorMessage = '';
      try {
        if (!this.versionData) {
          this.versionData = await this.createModelVersion();
        }
        const errors = this.versionData?.mlModelVersionCreate?.errors || [];

        if (errors.length) {
          this.errorMessage = errors.join(', ');
          this.versionData = null;
        } else {
          const { showPath, importPath } =
            this.versionData.mlModelVersionCreate.modelVersion._links;
          await this.$refs.importArtifactZoneRef.uploadArtifact(importPath);
          visitUrl(showPath);
        }
      } catch (error) {
        Sentry.captureException(error);
        this.errorMessage = error;
      }
    },
    resetModal() {
      this.version = null;
      this.description = '';
      this.errorMessage = null;
      this.versionData = null;
    },
    hideAlert() {
      this.errorMessage = null;
    },
    setDescription(newText) {
      if (!this.isSubmitting) {
        this.description = newText;
      }
    },
  },
  i18n: {},
  descriptionFormFieldProps: {
    placeholder: s__('MlModelRegistry|Enter a model version description'),
    id: 'model-version-description',
    name: 'model-version-description',
  },
  modal: {
    id: MODEL_VERSION_CREATION_MODAL_ID,
    actionSecondary: {
      text: __('Cancel'),
      attributes: { variant: 'default' },
    },
    versionDescription: s__('MlModelRegistry|Enter a semantic version.'),
    versionValid: s__('MlModelRegistry|Version is valid semantic version.'),
    versionInvalid: s__('MlModelRegistry|Version is not a valid semantic version.'),
    versionPlaceholder: s__('MlModelRegistry|For example 1.0.0'),
    descriptionPlaceholder: s__('MlModelRegistry|Enter some description'),
    buttonTitle: s__('MlModelRegistry|Create model version'),
    title: s__('MlModelRegistry|Create model version & import artifacts'),
    optionalText: s__('MlModelRegistry|(Optional)'),
  },
};
</script>

<template>
  <div>
    <gl-button v-gl-modal="$options.modal.id" variant="confirm" category="primary">{{
      $options.modal.buttonTitle
    }}</gl-button>
    <gl-modal
      :modal-id="$options.modal.id"
      :title="$options.modal.title"
      :action-primary="actionPrimary"
      :action-secondary="$options.modal.actionSecondary"
      size="lg"
      @primary="create"
      @secondary="resetModal"
    >
      <gl-form>
        <gl-form-group
          data-testid="versionDescriptionId"
          label="Version:"
          label-for="versionId"
          :state="isSemver"
          :invalid-feedback="!version ? '' : invalidFeedback"
          :valid-feedback="isSemver ? $options.modal.versionValid : ''"
          :description="versionDescription"
        >
          <gl-form-input
            id="versionId"
            v-model="version"
            data-testid="versionId"
            type="text"
            :placeholder="$options.modal.versionPlaceholder"
            autocomplete="off"
          />
        </gl-form-group>
        <gl-form-group
          label="Description"
          label-for="descriptionId"
          class="common-note-form gfm-form js-main-target-form new-note gl-grow"
          optional
          :optional-text="$options.modal.optionalText"
        >
          <markdown-editor
            ref="markdownEditor"
            data-testid="descriptionId"
            :value="description"
            enable-autocomplete
            :autocomplete-data-sources="autocompleteDataSources"
            :enable-content-editor="true"
            :form-field-props="$options.descriptionFormFieldProps"
            :render-markdown-path="markdownPreviewPath"
            :markdown-docs-path="markdownDocPath"
            :disable-attachments="disableAttachments"
            :placeholder="$options.modal.descriptionPlaceholder"
            :restricted-tool-bar-items="markdownEditorRestrictedToolBarItems"
            @input="setDescription"
          />
        </gl-form-group>
        <gl-form-group
          id="uploadArtifactsHeader"
          data-testid="uploadArtifactsHeader"
          label="Upload artifacts"
          label-for="versionImportArtifactZone"
        >
          <import-artifact-zone
            id="versionImportArtifactZone"
            ref="importArtifactZoneRef"
            class="gl-px-3 gl-py-0"
            :submit-on-select="false"
          />
        </gl-form-group>
      </gl-form>

      <gl-alert v-if="errorMessage" variant="danger" @dismiss="hideAlert">{{
        errorMessage
      }}</gl-alert>
    </gl-modal>
  </div>
</template>
