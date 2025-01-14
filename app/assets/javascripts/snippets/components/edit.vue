<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlLoadingIcon, GlFormInput, GlFormGroup } from '@gitlab/ui';

import eventHub from '~/blob/components/eventhub';
import { createAlert } from '~/alert';
import { visitUrl, joinPaths } from '~/lib/utils/url_utility';
import { __, sprintf } from '~/locale';
import {
  SNIPPET_MARK_EDIT_APP_START,
  SNIPPET_MEASURE_BLOBS_CONTENT,
} from '~/performance/constants';
import { performanceMarkAndMeasure } from '~/performance/utils';

import { SNIPPET_CREATE_MUTATION_ERROR, SNIPPET_UPDATE_MUTATION_ERROR } from '../constants';
import { getSnippetMixin } from '../mixins/snippets';
import CreateSnippetMutation from '../mutations/create_snippet.mutation.graphql';
import UpdateSnippetMutation from '../mutations/update_snippet.mutation.graphql';
import { markBlobPerformance } from '../utils/blob';
import { getErrorMessage } from '../utils/error';

import FormFooterActions from './form_footer_actions.vue';
import SnippetBlobActionsEdit from './snippet_blob_actions_edit.vue';
import SnippetDescriptionEdit from './snippet_description_edit.vue';
import SnippetVisibilityEdit from './snippet_visibility_edit.vue';

eventHub.$on(SNIPPET_MEASURE_BLOBS_CONTENT, markBlobPerformance);

export default {
  components: {
    SnippetDescriptionEdit,
    SnippetVisibilityEdit,
    SnippetBlobActionsEdit,
    FormFooterActions,
    GlButton,
    GlLoadingIcon,
    GlFormInput,
    GlFormGroup,
  },
  mixins: [getSnippetMixin],
  inject: ['selectedLevel'],
  props: {
    markdownPreviewPath: {
      type: String,
      required: true,
    },
    markdownDocsPath: {
      type: String,
      required: true,
    },
    visibilityHelpLink: {
      type: String,
      default: '',
      required: false,
    },
    projectPath: {
      type: String,
      default: '',
      required: false,
    },
  },
  data() {
    return {
      isUpdating: false,
      actions: [],
      snippet: {
        title: '',
        description: '',
        visibilityLevel: this.selectedLevel,
      },
      showValidation: false,
    };
  },
  computed: {
    hasBlobChanges() {
      return this.actions.length > 0;
    },
    hasNoChanges() {
      return (
        this.actions.every(
          (action) => !action.content && !action.filePath && !action.previousPath,
        ) &&
        !this.snippet.title &&
        !this.snippet.description
      );
    },
    hasValidBlobs() {
      return this.actions.every((x) => x.content);
    },
    isTitleValid() {
      return this.snippet.title !== '';
    },
    isFormValid() {
      return this.isTitleValid && this.hasValidBlobs;
    },
    isProjectSnippet() {
      return Boolean(this.projectPath);
    },
    apiData() {
      return {
        id: this.snippet.id,
        title: this.snippet.title,
        description: this.snippet.description,
        visibilityLevel: this.snippet.visibilityLevel,
        blobActions: this.actions,
      };
    },
    saveButtonLabel() {
      if (this.newSnippet) {
        return __('Create snippet');
      }
      return this.isUpdating ? __('Saving') : __('Save changes');
    },
    cancelButtonHref() {
      if (this.newSnippet) {
        return joinPaths('/', gon.relative_url_root, this.projectPath, '-/snippets');
      }
      return this.snippet.webUrl;
    },
    shouldShowBlobsErrors() {
      return this.showValidation && !this.hasValidBlobs;
    },
    shouldShowTitleErrors() {
      return this.showValidation && !this.isTitleValid;
    },
  },
  beforeCreate() {
    performanceMarkAndMeasure({ mark: SNIPPET_MARK_EDIT_APP_START });
  },
  created() {
    window.addEventListener('beforeunload', this.onBeforeUnload);
  },
  destroyed() {
    window.removeEventListener('beforeunload', this.onBeforeUnload);
  },
  methods: {
    onBeforeUnload(e = {}) {
      const returnValue = __('Are you sure you want to lose unsaved changes?');

      if (!this.hasBlobChanges || this.hasNoChanges || this.isUpdating) return undefined;

      Object.assign(e, { returnValue });
      return returnValue;
    },
    alertAPIFailure(err) {
      const defaultErrorMsg = this.newSnippet
        ? SNIPPET_CREATE_MUTATION_ERROR
        : SNIPPET_UPDATE_MUTATION_ERROR;
      createAlert({
        message: sprintf(defaultErrorMsg, { err }),
      });
      this.isUpdating = false;
    },
    getAttachedFiles() {
      const fileInputs = Array.from(this.$el.querySelectorAll('[name="files[]"]'));
      return fileInputs.map((node) => node.value);
    },
    createMutation() {
      return {
        mutation: CreateSnippetMutation,
        variables: {
          input: {
            ...this.apiData,
            uploadedFiles: this.getAttachedFiles(),
            projectPath: this.projectPath,
          },
        },
      };
    },
    updateMutation() {
      return {
        mutation: UpdateSnippetMutation,
        variables: {
          input: this.apiData,
        },
      };
    },
    handleFormSubmit() {
      this.showValidation = true;

      if (!this.isFormValid) {
        return;
      }

      this.isUpdating = true;

      this.$apollo
        .mutate(this.newSnippet ? this.createMutation() : this.updateMutation())
        .then(({ data }) => {
          const baseObj = this.newSnippet ? data?.createSnippet : data?.updateSnippet;

          const errors = baseObj?.errors;
          if (errors?.length) {
            this.alertAPIFailure(errors[0]);
          } else {
            visitUrl(baseObj.snippet.webUrl);
          }
        })
        .catch((e) => {
          // eslint-disable-next-line no-console
          console.error('[gitlab] unexpected error while updating snippet', e);

          this.alertAPIFailure(getErrorMessage(e));
        });
    },
    updateActions(actions) {
      this.actions = actions;
    },
  },
};
</script>
<template>
  <form
    class="snippet-form js-quick-submit common-note-form"
    :data-snippet-type="isProjectSnippet ? 'project' : 'personal'"
    data-testid="snippet-edit-form"
    @submit.prevent="handleFormSubmit"
  >
    <gl-loading-icon
      v-if="isLoading"
      :label="__('Loading snippet')"
      size="lg"
      class="loading-animation prepend-top-20 gl-mb-6"
    />
    <template v-else>
      <gl-form-group
        :label="__('Title')"
        label-for="snippet-title"
        :invalid-feedback="__('This field is required.')"
        :state="!shouldShowTitleErrors"
      >
        <gl-form-input
          id="snippet-title"
          v-model="snippet.title"
          data-testid="snippet-title-input-field"
          :autofocus="true"
        />
      </gl-form-group>

      <snippet-description-edit
        v-model="snippet.description"
        :markdown-preview-path="markdownPreviewPath"
        :markdown-docs-path="markdownDocsPath"
      />
      <snippet-blob-actions-edit
        :init-blobs="blobs"
        :is-valid="!shouldShowBlobsErrors"
        @actions="updateActions"
      />

      <snippet-visibility-edit
        v-model="snippet.visibilityLevel"
        :help-link="visibilityHelpLink"
        :is-project-snippet="isProjectSnippet"
      />
      <form-footer-actions>
        <template #prepend>
          <gl-button
            class="js-no-auto-disable gl-mr-2"
            category="primary"
            type="submit"
            variant="confirm"
            data-testid="submit-button"
            :disabled="isUpdating"
            >{{ saveButtonLabel }}</gl-button
          >
        </template>
        <template #append>
          <gl-button type="cancel" data-testid="snippet-cancel-btn" :href="cancelButtonHref">
            {{ __('Cancel') }}
          </gl-button>
        </template>
      </form-footer-actions>
    </template>
  </form>
</template>
