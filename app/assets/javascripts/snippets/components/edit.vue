<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';

import Flash from '~/flash';
import { __, sprintf } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import TitleField from '~/vue_shared/components/form/title.vue';
import { getBaseURL, joinPaths, redirectTo } from '~/lib/utils/url_utility';
import FormFooterActions from '~/vue_shared/components/form/form_footer_actions.vue';

import UpdateSnippetMutation from '../mutations/updateSnippet.mutation.graphql';
import CreateSnippetMutation from '../mutations/createSnippet.mutation.graphql';
import { getSnippetMixin } from '../mixins/snippets';
import { SNIPPET_VISIBILITY_PRIVATE } from '../constants';
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
      blob: {},
      fileName: '',
      content: '',
      isContentLoading: true,
      isUpdating: false,
      newSnippet: false,
    };
  },
  computed: {
    updatePrevented() {
      return this.snippet.title === '' || this.content === '' || this.isUpdating;
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
        fileName: this.fileName,
        content: this.content,
      };
    },
    saveButtonLabel() {
      if (this.newSnippet) {
        return __('Create snippet');
      }
      return this.isUpdating ? __('Saving') : __('Save changes');
    },
    cancelButtonHref() {
      return this.projectPath ? `/${this.projectPath}/snippets` : `/snippets`;
    },
    titleFieldId() {
      return `${this.isProjectSnippet ? 'project' : 'personal'}_snippet_title`;
    },
    descriptionFieldId() {
      return `${this.isProjectSnippet ? 'project' : 'personal'}_snippet_description`;
    },
  },
  methods: {
    updateFileName(newName) {
      this.fileName = newName;
    },
    flashAPIFailure(err) {
      Flash(sprintf(__("Can't update snippet: %{err}"), { err }));
    },
    onNewSnippetFetched() {
      this.newSnippet = true;
      this.snippet = this.$options.newSnippetSchema;
      this.blob = this.snippet.blob;
      this.isContentLoading = false;
    },
    onExistingSnippetFetched() {
      this.newSnippet = false;
      const { blob } = this.snippet;
      this.blob = blob;
      this.fileName = blob.name;
      const baseUrl = getBaseURL();
      const url = joinPaths(baseUrl, blob.rawPath);

      axios
        .get(url)
        .then(res => {
          this.content = res.data;
          this.isContentLoading = false;
        })
        .catch(e => this.flashAPIFailure(e));
    },
    onSnippetFetch(snippetRes) {
      if (snippetRes.data.snippets.edges.length === 0) {
        this.onNewSnippetFetched();
      } else {
        this.onExistingSnippetFetched();
      }
    },
    handleFormSubmit() {
      this.isUpdating = true;
      this.$apollo
        .mutate({
          mutation: this.newSnippet ? CreateSnippetMutation : UpdateSnippetMutation,
          variables: {
            input: {
              ...this.apiData,
              projectPath: this.newSnippet ? this.projectPath : undefined,
            },
          },
        })
        .then(({ data }) => {
          const baseObj = this.newSnippet ? data?.createSnippet : data?.updateSnippet;

          const errors = baseObj?.errors;
          if (errors.length) {
            this.flashAPIFailure(errors[0]);
          }
          redirectTo(baseObj.snippet.webUrl);
        })
        .catch(e => {
          this.isUpdating = false;
          this.flashAPIFailure(e);
        });
    },
  },
  newSnippetSchema: {
    title: '',
    description: '',
    visibilityLevel: SNIPPET_VISIBILITY_PRIVATE,
    blob: {},
  },
};
</script>
<template>
  <form
    class="snippet-form js-requires-input js-quick-submit common-note-form"
    :data-snippet-type="isProjectSnippet ? 'project' : 'personal'"
  >
    <gl-loading-icon
      v-if="isLoading"
      :label="__('Loading snippet')"
      size="lg"
      class="loading-animation prepend-top-20 append-bottom-20"
    />
    <template v-else>
      <title-field :id="titleFieldId" v-model="snippet.title" required :autofocus="true" />
      <snippet-description-edit
        :id="descriptionFieldId"
        v-model="snippet.description"
        :markdown-preview-path="markdownPreviewPath"
        :markdown-docs-path="markdownDocsPath"
      />
      <snippet-blob-edit
        v-model="content"
        :file-name="fileName"
        :is-loading="isContentLoading"
        @name-change="updateFileName"
      />
      <snippet-visibility-edit
        v-model="snippet.visibilityLevel"
        :help-link="visibilityHelpLink"
        :is-project-snippet="isProjectSnippet"
      />
      <form-footer-actions>
        <template #prepend>
          <gl-button
            type="submit"
            category="primary"
            variant="success"
            :disabled="updatePrevented"
            @click="handleFormSubmit"
            >{{ saveButtonLabel }}</gl-button
          >
        </template>
        <template #append>
          <gl-button :href="cancelButtonHref">{{ __('Cancel') }}</gl-button>
        </template>
      </form-footer-actions>
    </template>
  </form>
</template>
