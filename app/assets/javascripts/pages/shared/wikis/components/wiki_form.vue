<script>
import { GlForm, GlIcon, GlLink, GlButton, GlSprintf, GlAlert, GlLoadingIcon } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import csrf from '~/lib/utils/csrf';
import { setUrlFragment } from '~/lib/utils/url_utility';
import { s__, sprintf } from '~/locale';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

const MARKDOWN_LINK_TEXT = {
  markdown: '[Link Title](page-slug)',
  rdoc: '{Link title}[link:page-slug]',
  asciidoc: 'link:page-slug[Link title]',
  org: '[[page-slug]]',
};

export default {
  components: {
    GlAlert,
    GlForm,
    GlSprintf,
    GlIcon,
    GlLink,
    GlButton,
    MarkdownField,
    GlLoadingIcon,
    ContentEditor: () =>
      import(
        /* webpackChunkName: 'content_editor' */ '~/content_editor/components/content_editor.vue'
      ),
  },
  mixins: [glFeatureFlagMixin()],
  inject: ['formatOptions', 'pageInfo'],
  data() {
    return {
      title: this.pageInfo.title?.trim() || '',
      format: this.pageInfo.format || 'markdown',
      content: this.pageInfo.content?.trim() || '',
      isContentEditorLoading: true,
      useContentEditor: false,
      commitMessage: '',
      contentEditor: null,
      isDirty: false,
    };
  },
  computed: {
    csrfToken() {
      return csrf.token;
    },
    formAction() {
      return this.pageInfo.persisted ? this.pageInfo.path : this.pageInfo.createPath;
    },
    helpPath() {
      return setUrlFragment(
        this.pageInfo.helpPath,
        this.pageInfo.persisted ? 'move-a-wiki-page' : 'create-a-new-wiki-page',
      );
    },
    commitMessageI18n() {
      return this.pageInfo.persisted
        ? s__('WikiPage|Update %{pageTitle}')
        : s__('WikiPage|Create %{pageTitle}');
    },
    linkExample() {
      return MARKDOWN_LINK_TEXT[this.format];
    },
    submitButtonText() {
      if (this.pageInfo.persisted) return s__('WikiPage|Save changes');
      return s__('WikiPage|Create page');
    },
    cancelFormPath() {
      if (this.pageInfo.persisted) return this.pageInfo.path;
      return this.pageInfo.wikiPath;
    },
    wikiSpecificMarkdownHelpPath() {
      return setUrlFragment(this.pageInfo.markdownHelpPath, 'wiki-specific-markdown');
    },
    isMarkdownFormat() {
      return this.format === 'markdown';
    },
    showContentEditorButton() {
      return this.isMarkdownFormat && !this.useContentEditor && this.glFeatures.wikiContentEditor;
    },
    isContentEditorActive() {
      return this.isMarkdownFormat && this.useContentEditor;
    },
  },
  mounted() {
    this.updateCommitMessage();

    window.addEventListener('beforeunload', this.onPageUnload);
  },
  destroyed() {
    window.removeEventListener('beforeunload', this.onPageUnload);
  },
  methods: {
    getContentHTML(content) {
      return axios
        .post(this.pageInfo.markdownPreviewPath, { text: content })
        .then(({ data }) => data.body);
    },

    handleFormSubmit() {
      if (this.useContentEditor) {
        this.content = this.contentEditor.getSerializedContent();
      }

      this.isDirty = false;
    },

    handleContentChange() {
      this.isDirty = true;
    },

    onPageUnload(event) {
      if (!this.isDirty) return undefined;

      event.preventDefault();

      // eslint-disable-next-line no-param-reassign
      event.returnValue = '';
      return '';
    },

    updateCommitMessage() {
      if (!this.title) return;

      // Replace hyphens with spaces
      const newTitle = this.title.replace(/-+/g, ' ');

      const newCommitMessage = sprintf(this.commitMessageI18n, { pageTitle: newTitle }, false);
      this.commitMessage = newCommitMessage;
    },

    async initContentEditor() {
      this.isContentEditorLoading = true;
      this.useContentEditor = true;

      const { createContentEditor } = await import(
        /* webpackChunkName: 'content_editor' */ '~/content_editor/services/create_content_editor'
      );
      this.contentEditor =
        this.contentEditor ||
        createContentEditor({
          renderMarkdown: (markdown) => this.getContentHTML(markdown),
          tiptapOptions: {
            onUpdate: () => this.handleContentChange(),
          },
        });
      await this.contentEditor.setSerializedContent(this.content);

      this.isContentEditorLoading = false;
    },

    switchToOldEditor() {
      this.useContentEditor = false;
    },
  },
};
</script>

<template>
  <gl-form
    :action="formAction"
    method="post"
    class="wiki-form common-note-form gl-mt-3 js-quick-submit"
    @submit="handleFormSubmit"
  >
    <gl-alert
      v-if="isContentEditorActive"
      class="gl-mb-6"
      :dismissible="false"
      variant="danger"
      :primary-button-text="s__('WikiPage|Switch to old editor')"
      @primaryAction="switchToOldEditor()"
    >
      <p>
        {{
          s__(
            "WikiPage|You are editing this page with Content Editor. This editor is in beta and may not display the page's contents properly.",
          )
        }}
      </p>
      <p>
        {{
          s__(
            "WikiPage|Switching to the old editor will discard any changes you've made in the new editor.",
          )
        }}
      </p>
    </gl-alert>

    <input :value="csrfToken" type="hidden" name="authenticity_token" />
    <input v-if="pageInfo.persisted" type="hidden" name="_method" value="put" />
    <input
      :v-if="pageInfo.persisted"
      type="hidden"
      name="wiki[last_commit_sha]"
      :value="pageInfo.lastCommitSha"
    />
    <div class="form-group row">
      <div class="col-sm-2 col-form-label">
        <label class="control-label-full-width" for="wiki_title">{{ s__('WikiPage|Title') }}</label>
      </div>
      <div class="col-sm-10">
        <input
          id="wiki_title"
          v-model.trim="title"
          name="wiki[title]"
          type="text"
          class="form-control"
          data-qa-selector="wiki_title_textbox"
          :required="true"
          :autofocus="!pageInfo.persisted"
          :placeholder="s__('WikiPage|Page title')"
          @input="updateCommitMessage"
        />
        <span class="gl-display-inline-block gl-max-w-full gl-mt-2 gl-text-gray-600">
          <gl-icon class="gl-mr-n1" name="bulb" />
          {{
            pageInfo.persisted
              ? s__(
                  'WikiPage|Tip: You can move this page by adding the path to the beginning of the title.',
                )
              : s__(
                  'WikiPage|Tip: You can specify the full path for the new file. We will automatically create any missing directories.',
                )
          }}
          <gl-link :href="helpPath" target="_blank"
            ><gl-icon name="question-o" /> {{ s__('WikiPage|More Information.') }}</gl-link
          >
        </span>
      </div>
    </div>
    <div class="form-group row">
      <div class="col-sm-2 col-form-label">
        <label class="control-label-full-width" for="wiki_format">{{
          s__('WikiPage|Format')
        }}</label>
      </div>
      <div class="col-sm-10 gl-display-flex gl-flex-wrap">
        <select
          id="wiki_format"
          v-model="format"
          class="form-control"
          name="wiki[format]"
          :disabled="isContentEditorActive"
        >
          <option v-for="(key, label) of formatOptions" :key="key" :value="key">
            {{ label }}
          </option>
        </select>
        <gl-button
          v-if="showContentEditorButton"
          category="secondary"
          variant="confirm"
          class="gl-mt-4"
          @click="initContentEditor"
          >{{ s__('WikiPage|Use new editor') }}</gl-button
        >
      </div>
    </div>
    <div class="form-group row">
      <div class="col-sm-2 col-form-label">
        <label class="control-label-full-width" for="wiki_content">{{
          s__('WikiPage|Content')
        }}</label>
      </div>
      <div class="col-sm-10">
        <markdown-field
          v-if="!isContentEditorActive"
          :markdown-preview-path="pageInfo.markdownPreviewPath"
          :can-attach-file="true"
          :enable-autocomplete="true"
          :textarea-value="content"
          :markdown-docs-path="pageInfo.markdownHelpPath"
          :uploads-path="pageInfo.uploadsPath"
          class="bordered-box"
        >
          <template #textarea>
            <textarea
              id="wiki_content"
              ref="textarea"
              v-model.trim="content"
              name="wiki[content]"
              class="note-textarea js-gfm-input js-autosize markdown-area"
              dir="auto"
              data-supports-quick-actions="false"
              data-qa-selector="wiki_content_textarea"
              :autofocus="pageInfo.persisted"
              :aria-label="s__('WikiPage|Content')"
              :placeholder="s__('WikiPage|Write your content or drag files here…')"
              @input="handleContentChange"
            >
            </textarea>
          </template>
        </markdown-field>

        <div v-if="isContentEditorActive">
          <gl-loading-icon v-if="isContentEditorLoading" class="bordered-box gl-w-full gl-py-6" />
          <content-editor v-else :content-editor="contentEditor" />
          <input id="wiki_content" v-model.trim="content" type="hidden" name="wiki[content]" />
        </div>

        <div class="clearfix"></div>
        <div class="error-alert"></div>

        <div v-if="!isContentEditorActive" class="form-text gl-text-gray-600">
          <gl-sprintf
            :message="
              s__(
                'WikiPage|To link to a (new) page, simply type %{linkExample}. More examples are in the %{linkStart}documentation%{linkEnd}.',
              )
            "
          >
            <template #linkExample
              ><code>{{ linkExample }}</code></template
            >
            <template
              #link="// eslint-disable-next-line vue/no-template-shadow
                { content }"
              ><gl-link
                :href="wikiSpecificMarkdownHelpPath"
                target="_blank"
                data-testid="wiki-markdown-help-link"
                >{{ content }}</gl-link
              ></template
            >
          </gl-sprintf>
        </div>
      </div>
    </div>
    <div class="form-group row">
      <div class="col-sm-2 col-form-label">
        <label class="control-label-full-width" for="wiki_message">{{
          s__('WikiPage|Commit message')
        }}</label>
      </div>
      <div class="col-sm-10">
        <input
          id="wiki_message"
          v-model.trim="commitMessage"
          name="wiki[message]"
          type="text"
          class="form-control"
          data-qa-selector="wiki_message_textbox"
          :placeholder="s__('WikiPage|Commit message')"
        />
      </div>
    </div>
    <div class="form-actions">
      <gl-button
        category="primary"
        variant="confirm"
        type="submit"
        data-qa-selector="wiki_submit_button"
        data-testid="wiki-submit-button"
        :disabled="!content || !title"
        >{{ submitButtonText }}</gl-button
      >
      <gl-button :href="cancelFormPath" class="float-right">{{ s__('WikiPage|Cancel') }}</gl-button>
    </div>
  </gl-form>
</template>
