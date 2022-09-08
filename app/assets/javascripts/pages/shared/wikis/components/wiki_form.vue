<script>
import {
  GlForm,
  GlIcon,
  GlLink,
  GlButton,
  GlSprintf,
  GlFormGroup,
  GlFormInput,
  GlFormSelect,
  GlSegmentedControl,
} from '@gitlab/ui';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import axios from '~/lib/utils/axios_utils';
import csrf from '~/lib/utils/csrf';
import { setUrlFragment } from '~/lib/utils/url_utility';
import { s__, sprintf } from '~/locale';
import Tracking from '~/tracking';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import {
  CONTENT_EDITOR_LOADED_ACTION,
  SAVED_USING_CONTENT_EDITOR_ACTION,
  WIKI_CONTENT_EDITOR_TRACKING_LABEL,
  WIKI_FORMAT_LABEL,
  WIKI_FORMAT_UPDATED_ACTION,
} from '../constants';

const trackingMixin = Tracking.mixin({
  label: WIKI_CONTENT_EDITOR_TRACKING_LABEL,
});

const MARKDOWN_LINK_TEXT = {
  markdown: '[Link Title](page-slug)',
  rdoc: '{Link title}[link:page-slug]',
  asciidoc: 'link:page-slug[Link title]',
  org: '[[page-slug]]',
};

export default {
  i18n: {
    title: {
      label: s__('WikiPage|Title'),
      placeholder: s__('WikiPage|Page title'),
      helpText: {
        existingPage: s__(
          'WikiPage|Tip: You can move this page by adding the path to the beginning of the title.',
        ),
        newPage: s__(
          'WikiPage|Tip: You can specify the full path for the new file. We will automatically create any missing directories.',
        ),
        learnMore: s__('WikiPage|Learn more.'),
      },
    },
    format: {
      label: s__('WikiPage|Format'),
    },
    content: {
      label: s__('WikiPage|Content'),
      placeholder: s__('WikiPage|Write your content or drag files here…'),
    },
    linksHelpText: s__(
      'WikiPage|To link to a (new) page, simply type %{linkExample}. More examples are in the %{linkStart}documentation%{linkEnd}.',
    ),
    commitMessage: {
      label: s__('WikiPage|Commit message'),
      value: {
        existingPage: s__('WikiPage|Update %{pageTitle}'),
        newPage: s__('WikiPage|Create %{pageTitle}'),
      },
    },
    submitButton: {
      existingPage: s__('WikiPage|Save changes'),
      newPage: s__('WikiPage|Create page'),
    },
    cancel: s__('WikiPage|Cancel'),
  },
  switchEditingControlOptions: [
    { text: s__('Wiki Page|Source'), value: 'source' },
    { text: s__('Wiki Page|Rich text'), value: 'richText' },
  ],
  components: {
    GlIcon,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlSprintf,
    GlLink,
    GlButton,
    GlSegmentedControl,
    MarkdownField,
    LocalStorageSync,
    ContentEditor: () =>
      import(
        /* webpackChunkName: 'content_editor' */ '~/content_editor/components/content_editor.vue'
      ),
  },
  mixins: [trackingMixin],
  inject: ['formatOptions', 'pageInfo'],
  data() {
    return {
      editingMode: 'source',
      title: this.pageInfo.title?.trim() || '',
      format: this.pageInfo.format || 'markdown',
      content: this.pageInfo.content || '',
      commitMessage: '',
      isDirty: false,
      contentEditorEmpty: false,
      switchEditingControlDisabled: false,
    };
  },
  computed: {
    noContent() {
      return !this.content.trim();
    },
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
        ? this.$options.i18n.commitMessage.value.existingPage
        : this.$options.i18n.commitMessage.value.newPage;
    },
    linkExample() {
      return MARKDOWN_LINK_TEXT[this.format];
    },
    submitButtonText() {
      return this.pageInfo.persisted
        ? this.$options.i18n.submitButton.existingPage
        : this.$options.i18n.submitButton.newPage;
    },
    titleHelpText() {
      return this.pageInfo.persisted
        ? this.$options.i18n.title.helpText.existingPage
        : this.$options.i18n.title.helpText.newPage;
    },
    cancelFormPath() {
      if (this.pageInfo.persisted) return this.pageInfo.path;
      return this.pageInfo.wikiPath;
    },
    wikiSpecificMarkdownHelpPath() {
      return setUrlFragment(this.pageInfo.markdownHelpPath, 'wiki-specific-markdown');
    },
    contentEditorHelpPath() {
      return setUrlFragment(this.pageInfo.helpPath, 'gitlab-flavored-markdown-support');
    },
    isMarkdownFormat() {
      return this.format === 'markdown';
    },
    displayWikiSpecificMarkdownHelp() {
      return !this.isContentEditorActive;
    },
    disableSubmitButton() {
      return this.noContent || !this.title;
    },
    isContentEditorActive() {
      return this.isMarkdownFormat && this.useContentEditor;
    },
    useContentEditor() {
      return this.editingMode === 'richText';
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
    renderMarkdown(content) {
      return axios
        .post(this.pageInfo.markdownPreviewPath, { text: content })
        .then(({ data }) => data.body);
    },

    setEditingMode(editingMode) {
      this.editingMode = editingMode;
    },

    async handleFormSubmit(e) {
      e.preventDefault();

      if (this.useContentEditor) {
        this.trackFormSubmit();
      }

      this.trackWikiFormat();

      // Wait until form field values are refreshed
      await this.$nextTick();

      e.target.submit();

      this.isDirty = false;
    },

    handleContentChange() {
      this.isDirty = true;
    },

    handleContentEditorChange({ empty, markdown, changed }) {
      this.contentEditorEmpty = empty;
      this.isDirty = changed;
      this.content = markdown;
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

    trackContentEditorLoaded() {
      this.track(CONTENT_EDITOR_LOADED_ACTION);
    },

    trackFormSubmit() {
      if (this.isContentEditorActive) {
        this.track(SAVED_USING_CONTENT_EDITOR_ACTION);
      }
    },

    trackWikiFormat() {
      this.track(WIKI_FORMAT_UPDATED_ACTION, {
        label: WIKI_FORMAT_LABEL,
        extra: {
          project_path: this.pageInfo.path,
          old_format: this.pageInfo.format,
          value: this.format,
        },
      });
    },

    enableSwitchEditingControl() {
      this.switchEditingControlDisabled = false;
    },

    disableSwitchEditingControl() {
      this.switchEditingControlDisabled = true;
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
    <input :value="csrfToken" type="hidden" name="authenticity_token" />
    <input v-if="pageInfo.persisted" type="hidden" name="_method" value="put" />
    <input
      :v-if="pageInfo.persisted"
      type="hidden"
      name="wiki[last_commit_sha]"
      :value="pageInfo.lastCommitSha"
    />

    <div class="row">
      <div class="col-sm-9">
        <gl-form-group :label="$options.i18n.title.label" label-for="wiki_title">
          <template #description>
            <gl-icon class="gl-mr-n1" name="bulb" />
            {{ titleHelpText }}
            <gl-link :href="helpPath" target="_blank">
              {{ $options.i18n.title.helpText.learnMore }}
            </gl-link>
          </template>
          <gl-form-input
            id="wiki_title"
            v-model="title"
            name="wiki[title]"
            type="text"
            class="form-control"
            data-qa-selector="wiki_title_textbox"
            :required="true"
            :autofocus="!pageInfo.persisted"
            :placeholder="$options.i18n.title.placeholder"
            @input="updateCommitMessage"
          />
        </gl-form-group>
      </div>

      <div class="col-sm-3 row-sm-10">
        <gl-form-group :label="$options.i18n.format.label" label-for="wiki_format">
          <gl-form-select
            id="wiki_format"
            v-model="format"
            name="wiki[format]"
            :disabled="isContentEditorActive"
            class="form-control"
            :value="formatOptions.Markdown"
          >
            <option v-for="(key, label) of formatOptions" :key="key" :value="key">
              {{ label }}
            </option>
          </gl-form-select>
        </gl-form-group>
      </div>
    </div>

    <div class="row" data-testid="wiki-form-content-fieldset">
      <div class="col-sm-12 row-sm-5">
        <gl-form-group>
          <div v-if="isMarkdownFormat" class="gl-display-flex gl-justify-content-start gl-mb-3">
            <gl-segmented-control
              data-testid="toggle-editing-mode-button"
              data-qa-selector="editing_mode_button"
              class="gl-display-flex"
              :checked="editingMode"
              :options="$options.switchEditingControlOptions"
              :disabled="switchEditingControlDisabled"
              @input="setEditingMode"
            />
          </div>
          <local-storage-sync
            storage-key="gl-wiki-content-editor-enabled"
            :value="editingMode"
            @input="setEditingMode"
          />
          <markdown-field
            v-if="!isContentEditorActive"
            :markdown-preview-path="pageInfo.markdownPreviewPath"
            :can-attach-file="true"
            :enable-autocomplete="true"
            :textarea-value="content"
            :markdown-docs-path="pageInfo.markdownHelpPath"
            :uploads-path="pageInfo.uploadsPath"
            :enable-preview="isMarkdownFormat"
            class="bordered-box"
          >
            <template #textarea>
              <textarea
                id="wiki_content"
                ref="textarea"
                v-model="content"
                name="wiki[content]"
                class="note-textarea js-gfm-input js-autosize markdown-area"
                dir="auto"
                data-supports-quick-actions="false"
                data-qa-selector="wiki_content_textarea"
                :autofocus="pageInfo.persisted"
                :aria-label="$options.i18n.content.label"
                :placeholder="$options.i18n.content.placeholder"
                @input="handleContentChange"
              >
              </textarea>
            </template>
          </markdown-field>
          <div v-if="isContentEditorActive">
            <content-editor
              :render-markdown="renderMarkdown"
              :uploads-path="pageInfo.uploadsPath"
              :markdown="content"
              @initialized="trackContentEditorLoaded"
              @change="handleContentEditorChange"
              @loading="disableSwitchEditingControl"
              @loadingSuccess="enableSwitchEditingControl"
              @loadingError="enableSwitchEditingControl"
            />
            <input id="wiki_content" v-model.trim="content" type="hidden" name="wiki[content]" />
          </div>

          <div class="clearfix"></div>
          <div class="error-alert"></div>

          <div class="form-text gl-text-gray-600">
            <gl-sprintf
              v-if="displayWikiSpecificMarkdownHelp"
              :message="$options.i18n.linksHelpText"
            >
              <template #linkExample>
                <code>{{ linkExample }}</code>
              </template>
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
        </gl-form-group>
      </div>
    </div>

    <div class="row">
      <div class="col-sm-12 row-sm-5">
        <gl-form-group :label="$options.i18n.commitMessage.label" label-for="wiki_message">
          <gl-form-input
            id="wiki_message"
            v-model.trim="commitMessage"
            name="wiki[message]"
            type="text"
            class="form-control"
            data-qa-selector="wiki_message_textbox"
            :placeholder="$options.i18n.commitMessage.label"
          />
        </gl-form-group>
      </div>
    </div>

    <div class="form-actions">
      <gl-button
        category="primary"
        variant="confirm"
        type="submit"
        data-qa-selector="wiki_submit_button"
        data-testid="wiki-submit-button"
        :disabled="disableSubmitButton"
        >{{ submitButtonText }}</gl-button
      >
      <gl-button data-testid="wiki-cancel-button" :href="cancelFormPath" class="float-right">{{
        $options.i18n.cancel
      }}</gl-button>
    </div>
  </gl-form>
</template>
