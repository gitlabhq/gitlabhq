<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';

import { deprecatedCreateFlash as Flash } from '~/flash';
import { __, sprintf } from '~/locale';
import TitleField from '~/vue_shared/components/form/title.vue';
import { redirectTo, joinPaths } from '~/lib/utils/url_utility';
import FormFooterActions from '~/vue_shared/components/form/form_footer_actions.vue';
import {
  SNIPPET_MARK_EDIT_APP_START,
  SNIPPET_MEASURE_BLOBS_CONTENT,
} from '~/performance/constants';
import eventHub from '~/blob/components/eventhub';
import { performanceMarkAndMeasure } from '~/performance/utils';

import UpdateSnippetMutation from '../mutations/updateSnippet.mutation.graphql';
import CreateSnippetMutation from '../mutations/createSnippet.mutation.graphql';
import { getSnippetMixin } from '../mixins/snippets';
import { SNIPPET_CREATE_MUTATION_ERROR, SNIPPET_UPDATE_MUTATION_ERROR } from '../constants';
import { markBlobPerformance } from '../utils/blob';

import SnippetBlobActionsEdit from './snippet_blob_actions_edit.vue';
import SnippetVisibilityEdit from './snippet_visibility_edit.vue';
import SnippetDescriptionEdit from './snippet_description_edit.vue';

eventHub.$on(SNIPPET_MEASURE_BLOBS_CONTENT, markBlobPerformance);

export default {
  components: {
    SnippetDescriptionEdit,
    SnippetVisibilityEdit,
    SnippetBlobActionsEdit,
    TitleField,
    FormFooterActions,
    GlButton,
    GlLoadingIcon,
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
    };
  },
  computed: {
    hasBlobChanges() {
      return this.actions.length > 0;
    },
    hasValidBlobs() {
      return this.actions.every(x => x.content);
    },
    updatePrevented() {
      return this.snippet.title === '' || !this.hasValidBlobs || this.isUpdating;
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

      if (!this.hasBlobChanges || this.isUpdating) return undefined;

      Object.assign(e, { returnValue });
      return returnValue;
    },
    flashAPIFailure(err) {
      const defaultErrorMsg = this.newSnippet
        ? SNIPPET_CREATE_MUTATION_ERROR
        : SNIPPET_UPDATE_MUTATION_ERROR;
      Flash(sprintf(defaultErrorMsg, { err }));
      this.isUpdating = false;
    },
    getAttachedFiles() {
      const fileInputs = Array.from(this.$el.querySelectorAll('[name="files[]"]'));
      return fileInputs.map(node => node.value);
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
      this.isUpdating = true;
      this.$apollo
        .mutate(this.newSnippet ? this.createMutation() : this.updateMutation())
        .then(({ data }) => {
          const baseObj = this.newSnippet ? data?.createSnippet : data?.updateSnippet;

          const errors = baseObj?.errors;
          if (errors.length) {
            this.flashAPIFailure(errors[0]);
          } else {
            redirectTo(baseObj.snippet.webUrl);
          }
        })
        .catch(e => {
          this.flashAPIFailure(e);
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
      <title-field
        id="snippet-title"
        v-model="snippet.title"
        data-qa-selector="snippet_title_field"
        required
        :autofocus="true"
      />
      <snippet-description-edit
        v-model="snippet.description"
        :markdown-preview-path="markdownPreviewPath"
        :markdown-docs-path="markdownDocsPath"
      />
      <snippet-blob-actions-edit :init-blobs="blobs" @actions="updateActions" />

      <snippet-visibility-edit
        v-model="snippet.visibilityLevel"
        :help-link="visibilityHelpLink"
        :is-project-snippet="isProjectSnippet"
      />
      <form-footer-actions>
        <template #prepend>
          <gl-button
            category="primary"
            type="submit"
            variant="success"
            :disabled="updatePrevented"
            data-qa-selector="submit_button"
            data-testid="snippet-submit-btn"
            >{{ saveButtonLabel }}</gl-button
          >
        </template>
        <template #append>
          <gl-button type="cancel" data-testid="snippet-cancel-btn" :href="cancelButtonHref">{{
            __('Cancel')
          }}</gl-button>
        </template>
      </form-footer-actions>
    </template>
  </form>
</template>
