<script>
import { GlAlert, GlButton, GlForm, GlFormGroup } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import editModelVersionMutation from '../graphql/mutations/edit_model_version.mutation.graphql';
import { emptyArtifactFile } from '../constants';

export default {
  name: 'ModelVersionEdit',
  components: {
    PageHeading,
    MarkdownEditor,
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
  },
  props: {
    modelWithVersion: {
      type: Object,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
    markdownPreviewPath: {
      type: String,
      required: true,
    },
    modelVersionPath: {
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
      errorMessage: null,
      markdownDocPath: helpPagePath('user/markdown'),
      markdownEditorRestrictedToolBarItems: ['full-screen'],
      description: this.modelWithVersion.version.description,
    };
  },
  computed: {
    autocompleteDataSources() {
      return gl.GfmAutoComplete?.dataSources;
    },
  },
  methods: {
    async edit() {
      this.errorMessage = '';
      try {
        const { data } = await this.$apollo.mutate({
          mutation: editModelVersionMutation,
          variables: {
            projectPath: this.projectPath,
            modelId: this.modelWithVersion.id,
            version: this.modelWithVersion.version.version,
            description: this.description,
          },
        });
        const modelErrors = data?.mlModelVersionEdit?.errors || [];
        if (modelErrors.length) {
          this.errorMessage = modelErrors.join(', ');
        } else {
          const { showPath } = data.mlModelVersionEdit.modelVersion._links;
          visitUrl(showPath);
        }
      } catch (error) {
        Sentry.captureException(error);
        this.errorMessage = error;
        this.selectedFile = emptyArtifactFile;
      }
    },
    hideAlert() {
      this.errorMessage = null;
    },
    setDescription(newText) {
      this.description = newText;
    },
  },
  descriptionFormFieldProps: {
    placeholder: s__('MlModelRegistry|Enter a model version description'),
    id: 'model-version-description',
    name: 'model-version-description',
  },
  i18n: {
    actionPrimaryText: s__('MlModelRegistry|Save changes'),
    actionSecondaryText: __('Cancel'),
    descriptionPlaceholder: s__('MlModelRegistry|Enter some description'),
    descriptionLabel: s__('MlModelRegistry|Description'),
    title: s__('MlModelRegistry|Edit model version'),
    optionalText: s__('MlModelRegistry|(Optional)'),
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="errorMessage"
      data-testid="edit-alert"
      variant="danger"
      class="gl-mt-5"
      @dismiss="hideAlert"
      >{{ errorMessage }}
    </gl-alert>

    <page-heading :heading="$options.i18n.title" />

    <gl-form>
      <gl-form-group
        :label="$options.i18n.descriptionLabel"
        data-testid="description-group-id"
        label-for="descriptionId"
        optional
        :optional-text="$options.i18n.optionalText"
        class="common-note-form gfm-form js-main-target-form new-note gl-grow"
      >
        <markdown-editor
          ref="markdownEditor"
          data-testid="description-id"
          :value="modelWithVersion.version.description"
          enable-autocomplete
          :autocomplete-data-sources="autocompleteDataSources"
          enable-content-editor
          :form-field-props="$options.descriptionFormFieldProps"
          :render-markdown-path="markdownPreviewPath"
          :markdown-docs-path="markdownDocPath"
          :disable-attachments="disableAttachments"
          :placeholder="$options.i18n.nameDescriptionPlaceholder"
          :restricted-tool-bar-items="markdownEditorRestrictedToolBarItems"
          @input="setDescription"
        />

        <div class="gl-mt-5 gl-flex gl-gap-3">
          <gl-button data-testid="primary-button" variant="confirm" @click="edit"
            >{{ $options.i18n.actionPrimaryText }}
          </gl-button>
          <gl-button data-testid="secondary-button" variant="default" :href="modelVersionPath"
            >{{ $options.i18n.actionSecondaryText }}
          </gl-button>
        </div>
      </gl-form-group>
    </gl-form>
  </div>
</template>
