<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';

import Flash from '~/flash';
import { __, sprintf } from '~/locale';
import TitleField from '~/vue_shared/components/form/title.vue';
import { redirectTo } from '~/lib/utils/url_utility';
import FormFooterActions from '~/vue_shared/components/form/form_footer_actions.vue';

import UpdateSnippetMutation from '../mutations/updateSnippet.mutation.graphql';
import CreateSnippetMutation from '../mutations/createSnippet.mutation.graphql';
import { getSnippetMixin } from '../mixins/snippets';
import {
  SNIPPET_VISIBILITY_PRIVATE,
  SNIPPET_CREATE_MUTATION_ERROR,
  SNIPPET_UPDATE_MUTATION_ERROR,
  SNIPPET_BLOB_ACTION_CREATE,
  SNIPPET_BLOB_ACTION_UPDATE,
  SNIPPET_BLOB_ACTION_MOVE,
} from '../constants';
import SnippetBlobEdit from './snippet_blob_edit.vue';
import SnippetVisibilityEdit from './snippet_visibility_edit.vue';
import SnippetDescriptionEdit from './snippet_description_edit.vue';

export default {
  components: {
    SnippetDescriptionEdit,
    SnippetVisibilityEdit,
    SnippetBlobEdit,
    TitleField,
    FormFooterActions,
    GlButton,
    GlLoadingIcon,
  },
  mixins: [getSnippetMixin],
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
      blobsActions: {},
      isUpdating: false,
      newSnippet: false,
    };
  },
  computed: {
    getActionsEntries() {
      return Object.values(this.blobsActions);
    },
    allBlobsHaveContent() {
      const entries = this.getActionsEntries;
      return entries.length > 0 && !entries.find(action => !action.content);
    },
    allBlobChangesRegistered() {
      const entries = this.getActionsEntries;
      return entries.length > 0 && !entries.find(action => action.action === '');
    },
    updatePrevented() {
      return this.snippet.title === '' || !this.allBlobsHaveContent || this.isUpdating;
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
        blobActions: this.getActionsEntries.filter(entry => entry.action !== ''),
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
        return this.projectPath ? `/${this.projectPath}/snippets` : `/snippets`;
      }
      return this.snippet.webUrl;
    },
    titleFieldId() {
      return `${this.isProjectSnippet ? 'project' : 'personal'}_snippet_title`;
    },
    descriptionFieldId() {
      return `${this.isProjectSnippet ? 'project' : 'personal'}_snippet_description`;
    },
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

      if (!this.allBlobChangesRegistered || this.isUpdating) return undefined;

      Object.assign(e, { returnValue });
      return returnValue;
    },
    updateBlobActions(args = {}) {
      // `_constants` is the internal prop that
      // should not be sent to the mutation. Hence we filter it out from
      // the argsToUpdateAction that is the data-basis for the mutation.
      const { _constants: blobConstants, ...argsToUpdateAction } = args;
      const { previousPath, filePath, content } = argsToUpdateAction;
      let actionEntry = this.blobsActions[blobConstants.id] || {};
      let tunedActions = {
        action: '',
        previousPath,
      };

      if (this.newSnippet) {
        // new snippet, hence new blob
        tunedActions = {
          action: SNIPPET_BLOB_ACTION_CREATE,
          previousPath: '',
        };
      } else if (previousPath && filePath) {
        // renaming of a blob + renaming & content update
        const renamedToOriginal = filePath === blobConstants.originalPath;
        tunedActions = {
          action: renamedToOriginal ? SNIPPET_BLOB_ACTION_UPDATE : SNIPPET_BLOB_ACTION_MOVE,
          previousPath: !renamedToOriginal ? blobConstants.originalPath : '',
        };
      } else if (content !== blobConstants.originalContent) {
        // content update only
        tunedActions = {
          action: SNIPPET_BLOB_ACTION_UPDATE,
          previousPath: '',
        };
      }

      actionEntry = { ...actionEntry, ...argsToUpdateAction, ...tunedActions };

      this.$set(this.blobsActions, blobConstants.id, actionEntry);
    },
    flashAPIFailure(err) {
      const defaultErrorMsg = this.newSnippet
        ? SNIPPET_CREATE_MUTATION_ERROR
        : SNIPPET_UPDATE_MUTATION_ERROR;
      Flash(sprintf(defaultErrorMsg, { err }));
      this.isUpdating = false;
    },
    onNewSnippetFetched() {
      this.newSnippet = true;
      this.snippet = this.$options.newSnippetSchema;
    },
    onExistingSnippetFetched() {
      this.newSnippet = false;
    },
    onSnippetFetch(snippetRes) {
      if (snippetRes.data.snippets.edges.length === 0) {
        this.onNewSnippetFetched();
      } else {
        this.onExistingSnippetFetched();
      }
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
            this.originalContent = this.content;
            redirectTo(baseObj.snippet.webUrl);
          }
        })
        .catch(e => {
          this.flashAPIFailure(e);
        });
    },
  },
  newSnippetSchema: {
    title: '',
    description: '',
    visibilityLevel: SNIPPET_VISIBILITY_PRIVATE,
  },
};
</script>
<template>
  <form
    class="snippet-form js-requires-input js-quick-submit common-note-form"
    :data-snippet-type="isProjectSnippet ? 'project' : 'personal'"
    data-testid="snippet-edit-form"
    @submit.prevent="handleFormSubmit"
  >
    <gl-loading-icon
      v-if="isLoading"
      :label="__('Loading snippet')"
      size="lg"
      class="loading-animation prepend-top-20 append-bottom-20"
    />
    <template v-else>
      <title-field
        :id="titleFieldId"
        v-model="snippet.title"
        data-qa-selector="snippet_title_field"
        required
        :autofocus="true"
      />
      <snippet-description-edit
        :id="descriptionFieldId"
        v-model="snippet.description"
        :markdown-preview-path="markdownPreviewPath"
        :markdown-docs-path="markdownDocsPath"
      />
      <template v-if="blobs.length">
        <snippet-blob-edit
          v-for="blob in blobs"
          :key="blob.name"
          :blob="blob"
          @blob-updated="updateBlobActions"
        />
      </template>
      <snippet-blob-edit v-else @blob-updated="updateBlobActions" />

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
