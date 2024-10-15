<script>
import { GlAlert, GlButton, GlForm, GlFormGroup, GlModal, GlModalDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import editModelVersionMutation from '../graphql/mutations/edit_model_version.mutation.graphql';
import { emptyArtifactFile, MODEL_VERSION_EDIT_MODAL_ID } from '../constants';

export default {
  name: 'ModelVersionEdit',
  components: {
    MarkdownEditor,
    GlAlert,
    GlButton,
    GlModal,
    GlForm,
    GlFormGroup,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: ['projectPath', 'maxAllowedFileSize', 'markdownPreviewPath'],
  props: {
    modelWithVersion: {
      type: Object,
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
    actionPrimary() {
      return {
        text: s__('MlModelRegistry|Save changes'),
        attributes: { variant: 'confirm' },
      };
    },
  },
  methods: {
    async edit($event) {
      $event.preventDefault();

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
  modal: {
    id: MODEL_VERSION_EDIT_MODAL_ID,
    actionSecondary: {
      text: __('Cancel'),
      attributes: { variant: 'default' },
    },
    descriptionPlaceholder: s__('MlModelRegistry|Enter some description'),
    descriptionLabel: s__('MlModelRegistry|Description'),
    editButtonLabel: s__('MlModelRegistry|Edit model version'),
    title: s__('MlModelRegistry|Edit version'),
    optionalText: s__('MlModelRegistry|(Optional)'),
  },
};
</script>

<template>
  <div>
    <gl-button v-gl-modal="$options.modal.id">{{ $options.modal.editButtonLabel }}</gl-button>
    <gl-modal
      :modal-id="$options.modal.id"
      :title="$options.modal.title"
      :action-primary="actionPrimary"
      :action-secondary="$options.modal.actionSecondary"
      size="lg"
      @primary="edit"
    >
      <gl-form>
        <gl-form-group
          :label="$options.modal.descriptionLabel"
          data-testid="description-group-id"
          label-for="descriptionId"
          optional
          :optional-text="$options.modal.optionalText"
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
            :placeholder="$options.modal.nameDescriptionPlaceholder"
            :restricted-tool-bar-items="markdownEditorRestrictedToolBarItems"
            @input="setDescription"
          />
        </gl-form-group>
      </gl-form>

      <gl-alert
        v-if="errorMessage"
        data-testid="modal-edit-alert"
        variant="danger"
        @dismiss="hideAlert"
        >{{ errorMessage }}
      </gl-alert>
    </gl-modal>
  </div>
</template>
