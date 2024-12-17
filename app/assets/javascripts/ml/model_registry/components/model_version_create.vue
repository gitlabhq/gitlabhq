<script>
import { GlAlert, GlButton, GlForm, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { visitUrl, visitUrlWithAlerts } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { semverRegex } from '~/lib/utils/regexp';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import createModelVersionMutation from '../graphql/mutations/create_model_version.mutation.graphql';

export default {
  name: 'ModelVersionCreate',
  components: {
    PageHeading,
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    MarkdownEditor,
    ImportArtifactZone: () => import('./import_artifact_zone.vue'),
  },
  inject: ['maxAllowedFileSize', 'latestVersion', 'modelGid'],
  props: {
    disableAttachments: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectPath: {
      type: String,
      required: true,
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
    modelPath: {
      type: String,
      required: true,
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
      importErrorsText: null,
    };
  },
  computed: {
    versionDescription() {
      if (this.latestVersion) {
        return sprintf(
          s__('MlModelRegistry|Must be a semantic version. Latest version is %{latestVersion}'),
          {
            latestVersion: this.latestVersion,
          },
        );
      }
      return s__('MlModelRegistry|Must be a semantic version.');
    },
    autocompleteDataSources() {
      return gl.GfmAutoComplete?.dataSources;
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
        return this.$options.i18n.versionInvalid;
      }
      this.submitAvailable();
      return null;
    },
    importErrorsAlert() {
      return {
        id: 'import-artifact-alert',
        variant: this.importErrorsText ? 'danger' : 'info',
        message: this.importErrorsText
          ? `${this.$options.i18n.someFailed} ${this.importErrorsText}`
          : this.$options.i18n.allSucceeded,
      };
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
    async create() {
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
          visitUrlWithAlerts(showPath, [this.importErrorsAlert]);
        }
      } catch (error) {
        Sentry.captureException(error);
        this.errorMessage = error;
      }
    },
    cancel() {
      visitUrl(this.modelPath);
    },
    hideAlert() {
      this.errorMessage = null;
    },
    setDescription(newText) {
      if (!this.isSubmitting) {
        this.description = newText;
      }
    },
    onImportError(error) {
      this.importErrorsText = error;
    },
  },
  descriptionFormFieldProps: {
    placeholder: s__('MlModelRegistry|Enter a model version description'),
    id: 'model-version-description',
    name: 'model-version-description',
  },
  i18n: {
    allSucceeded: s__('MlModelRegistry|Artifacts uploaded successfully.'),
    someFailed: s__('MlModelRegistry|Artifact uploads completed with errors.'),
    actionPrimaryText: s__('MlModelRegistry|Create & import'),
    actionSecondaryText: __('Cancel'),
    versionDescription: s__('MlModelRegistry|Enter a semantic version.'),
    versionValid: s__('MlModelRegistry|Version is valid semantic version.'),
    versionInvalid: s__('MlModelRegistry|Version is not a valid semantic version.'),
    versionPlaceholder: s__('MlModelRegistry|For example 1.0.0'),
    descriptionPlaceholder: s__('MlModelRegistry|Enter some description'),
    title: s__('MlModelRegistry|New version'),
    description: s__(
      'MlModelRegistry|Models have different versions. You can deploy and test versions. Complete the following fields to create a new version of the model.',
    ),
    optionalText: s__('MlModelRegistry|(Optional)'),
    versionLabelText: s__('MlModelRegistry|Version'),
    versionDescriptionText: s__('MlModelRegistry|Description'),
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="errorMessage"
      class="gl-mt-5"
      data-testid="create-alert"
      variant="danger"
      @dismiss="hideAlert"
      >{{ errorMessage }}
    </gl-alert>

    <page-heading :heading="$options.i18n.title">
      <template #description>
        {{ $options.i18n.description }}
      </template>
    </page-heading>

    <gl-form>
      <gl-form-group
        data-testid="versionDescriptionId"
        :label="$options.i18n.versionLabelText"
        label-for="versionId"
        :state="isSemver"
        :invalid-feedback="!version ? '' : invalidFeedback"
        :valid-feedback="isSemver ? $options.i18n.versionValid : ''"
        :description="versionDescription"
      >
        <gl-form-input
          id="versionId"
          v-model="version"
          data-testid="versionId"
          type="text"
          required
          :placeholder="$options.i18n.versionPlaceholder"
          autocomplete="off"
        />
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.versionDescriptionText"
        label-for="descriptionId"
        class="common-note-form gfm-form js-main-target-form new-note gl-grow"
        optional
        :optional-text="$options.i18n.optionalText"
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
          :placeholder="$options.i18n.descriptionPlaceholder"
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
          class="gl-px-0 gl-py-0"
          :submit-on-select="false"
          @error="onImportError"
        />
      </gl-form-group>

      <div class="gl-flex gl-gap-3">
        <gl-button
          data-testid="primary-button"
          variant="confirm"
          :disabled="submitButtonDisabled"
          @click="create"
          >{{ $options.i18n.actionPrimaryText }}
        </gl-button>
        <gl-button data-testid="secondary-button" variant="default" @click="cancel"
          >{{ $options.i18n.actionSecondaryText }}
        </gl-button>
      </div>
    </gl-form>
  </div>
</template>
