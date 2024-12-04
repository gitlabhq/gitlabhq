<script>
import { GlAlert, GlButton, GlForm, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { noSpacesRegex } from '~/lib/utils/regexp';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import editModelMutation from '../graphql/mutations/edit_model.mutation.graphql';

export default {
  name: 'ModelEdit',
  components: {
    PageHeading,
    MarkdownEditor,
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
  },
  props: {
    model: {
      type: Object,
      required: true,
    },
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
      errorMessage: null,
      modelData: null,
      markdownDocPath: helpPagePath('user/markdown'),
      markdownEditorRestrictedToolBarItems: ['full-screen'],
      description: this.model.description,
    };
  },
  computed: {
    autocompleteDataSources() {
      return gl.GfmAutoComplete?.dataSources;
    },
    modelNameIsValid() {
      return this.model.name && noSpacesRegex.test(this.model.name);
    },
    modelNameDescription() {
      return !this.model.name || this.modelNameIsValid ? this.$options.i18n.nameDescription : '';
    },
  },
  methods: {
    async edit() {
      this.errorMessage = '';

      try {
        const { data } = await this.$apollo.mutate({
          mutation: editModelMutation,
          variables: {
            projectPath: this.projectPath,
            modelId: getIdFromGraphQLId(this.model.id),
            name: this.model.name,
            description: this.description,
          },
        });
        const modelErrors = data?.mlModelEdit?.errors || [];
        if (modelErrors.length) {
          this.errorMessage = modelErrors.join(', ');
        } else {
          const { showPath } = data.mlModelEdit.model._links;
          visitUrl(showPath);
        }
      } catch (error) {
        Sentry.captureException(error);
        this.errorMessage = error;
      }
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
  descriptionFormFieldProps: {
    placeholder: s__('MlModelRegistry|Enter a model description'),
    id: 'model-description',
    name: 'model-description',
  },
  i18n: {
    actionSecondaryText: __('Cancel'),
    actionPrimaryText: s__('MlModelRegistry|Save changes'),
    nameDescriptionLabel: s__('MlModelRegistry|Must be unique. May not contain spaces.'),
    nameDescription: s__('MlModelRegistry|Example: my-model'),
    nameInvalid: s__('MlModelRegistry|May not contain spaces.'),
    nameDescriptionPlaceholder: s__('MlModelRegistry|Enter a model description'),
    title: s__('MlModelRegistry|Edit model'),
    modelName: s__('MlModelRegistry|Model name'),
    modelDescription: __('Model description'),
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
        :label="$options.i18n.modelName"
        :label-description="$options.i18n.nameDescriptionLabel"
        label-for="nameId"
        data-testid="nameGroupId"
        :state="modelNameIsValid"
        :invalid-feedback="$options.i18n.nameInvalid"
        :description="modelNameDescription"
      >
        <gl-form-input
          id="nameId"
          :value="model.name"
          data-testid="nameId"
          type="text"
          required
          :disabled="true"
        />
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.modelDescription"
        data-testid="descriptionGroupId"
        label-for="descriptionId"
        optional
        :optional-text="$options.i18n.optionalText"
        class="common-note-form gfm-form js-main-target-form new-note gl-grow"
      >
        <markdown-editor
          ref="markdownEditor"
          data-testid="descriptionId"
          :value="model.description"
          enable-autocomplete
          :autocomplete-data-sources="autocompleteDataSources"
          :enable-content-editor="true"
          :form-field-props="$options.descriptionFormFieldProps"
          :render-markdown-path="markdownPreviewPath"
          :markdown-docs-path="markdownDocPath"
          :disable-attachments="disableAttachments"
          :placeholder="$options.i18n.nameDescriptionPlaceholder"
          :restricted-tool-bar-items="markdownEditorRestrictedToolBarItems"
          @input="setDescription"
        />
      </gl-form-group>

      <div class="gl-flex gl-gap-3">
        <gl-button data-testid="primary-button" variant="confirm" @click="edit"
          >{{ $options.i18n.actionPrimaryText }}
        </gl-button>
        <gl-button data-testid="secondary-button" variant="default" :href="modelPath"
          >{{ $options.i18n.actionSecondaryText }}
        </gl-button>
      </div>
    </gl-form>
  </div>
</template>
