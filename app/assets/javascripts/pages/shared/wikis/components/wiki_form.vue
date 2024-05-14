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
} from '@gitlab/ui';
import { getDraft, clearDraft, updateDraft } from '~/lib/utils/autosave';
import csrf from '~/lib/utils/csrf';
import { setUrlFragment } from '~/lib/utils/url_utility';
import { s__, sprintf } from '~/locale';
import Tracking from '~/tracking';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';
import {
  WIKI_CONTENT_EDITOR_TRACKING_LABEL,
  WIKI_FORMAT_LABEL,
  WIKI_FORMAT_UPDATED_ACTION,
  CONTENT_EDITOR_LOADED_ACTION,
} from '../constants';
import { isTemplate } from '../utils';
import WikiTemplate from './wiki_template.vue';

const trackingMixin = Tracking.mixin({
  label: WIKI_CONTENT_EDITOR_TRACKING_LABEL,
});

const MARKDOWN_LINK_TEXT = {
  markdown: '[Link Title](page-slug)',
  rdoc: '{Link title}[link:page-slug]',
  asciidoc: 'link:page-slug[Link title]',
  org: '[[page-slug]]',
};

function getPagePath(pageInfo) {
  return pageInfo.persisted ? pageInfo.path : pageInfo.createPath;
}

const autosaveKey = (pageInfo, field) => {
  const path = pageInfo.persisted ? pageInfo.path : pageInfo.createPath;

  return `${path}/${field}`;
};

const titleAutosaveKey = (pageInfo) => autosaveKey(pageInfo, 'title');
const formatAutosaveKey = (pageInfo) => autosaveKey(pageInfo, 'format');
const contentAutosaveKey = (pageInfo) => autosaveKey(pageInfo, 'content');
const commitAutosaveKey = (pageInfo) => autosaveKey(pageInfo, 'commit');

const getTitle = (pageInfo) => getDraft(titleAutosaveKey(pageInfo)) || pageInfo.title?.trim() || '';
const getFormat = (pageInfo) =>
  getDraft(formatAutosaveKey(pageInfo)) || pageInfo.format || 'markdown';
const getContent = (pageInfo) => getDraft(contentAutosaveKey(pageInfo)) || pageInfo.content || '';
const getCommitMessage = (pageInfo) =>
  getDraft(commitAutosaveKey(pageInfo)) || pageInfo.commitMessage || '';
const getIsFormDirty = (pageInfo) => Boolean(getDraft(titleAutosaveKey(pageInfo)));

export default {
  i18n: {
    title: {
      label: s__('WikiPage|Title'),
      placeholder: s__('WikiPage|Page title'),
      templatePlaceholder: s__('WikiPage|Template title'),
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
        existingTemplate: s__('WikiPage|Update template %{pageTitle}'),
        newTemplatePage: s__('WikiPage|Create template %{pageTitle}'),
      },
    },
    submitButton: {
      existingPage: s__('WikiPage|Save changes'),
      newPage: s__('WikiPage|Create page'),
      newTemplate: s__('WikiPage|Create template'),
    },
    cancel: s__('WikiPage|Cancel'),
  },
  components: {
    GlIcon,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlSprintf,
    GlLink,
    GlButton,
    MarkdownEditor,
    WikiTemplate,
  },
  mixins: [trackingMixin],
  inject: ['formatOptions', 'pageInfo', 'drawioUrl', 'templates'],
  data() {
    const title = window.location.href.includes('random_title=true') ? '' : getTitle(this.pageInfo);
    return {
      editingMode: 'source',
      title,
      pageTitle: title.replace('templates/', ''),
      format: getFormat(this.pageInfo),
      content: getContent(this.pageInfo),
      commitMessage: getCommitMessage(this.pageInfo),
      contentEditorEmpty: false,
      isContentEditorActive: false,
      switchEditingControlDisabled: false,
      isFormDirty: getIsFormDirty(this.pageInfo),
      formFieldProps: {
        placeholder: this.$options.i18n.content.placeholder,
        'aria-label': this.$options.i18n.content.label,
        id: 'wiki_content',
        name: 'wiki[content]',
        class: 'note-textarea',
      },
    };
  },
  computed: {
    isTemplate,
    titlePlaceholder() {
      return this.isTemplate
        ? this.$options.i18n.title.templatePlaceholder
        : this.$options.i18n.title.placeholder;
    },
    autocompleteDataSources() {
      return gl.GfmAutoComplete?.dataSources;
    },
    noContent() {
      return !this.content.trim();
    },
    csrfToken() {
      return csrf.token;
    },
    formAction() {
      return getPagePath(this.pageInfo);
    },
    helpPath() {
      return setUrlFragment(
        this.pageInfo.helpPath,
        this.pageInfo.persisted ? 'move-a-wiki-page' : 'create-a-new-wiki-page',
      );
    },
    commitMessageI18n() {
      if (this.pageInfo.persisted) {
        if (this.isTemplate) return this.$options.i18n.commitMessage.value.existingTemplate;
        return this.$options.i18n.commitMessage.value.existingPage;
      }
      if (this.isTemplate) return this.$options.i18n.commitMessage.value.newTemplatePage;
      return this.$options.i18n.commitMessage.value.newPage;
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
    drawioEnabled() {
      return typeof this.drawioUrl === 'string' && this.drawioUrl.length > 0;
    },
  },
  watch: {
    title() {
      this.updateCommitMessage();
    },
    pageTitle() {
      this.title = this.isTemplate ? `templates/${this.pageTitle}` : this.pageTitle;
    },
  },
  mounted() {
    if (!this.commitMessage) this.updateCommitMessage();

    window.addEventListener('beforeunload', this.onPageUnload);
  },
  destroyed() {
    window.removeEventListener('beforeunload', this.onPageUnload);
  },
  methods: {
    async handleFormSubmit(e) {
      this.isFormDirty = false;

      e.preventDefault();

      this.trackFormSubmit();
      this.trackWikiFormat();

      // Wait until form field values are refreshed
      await this.$nextTick();

      e.target.submit();
    },

    updateDrafts() {
      updateDraft(titleAutosaveKey(this.pageInfo), this.title);
      updateDraft(formatAutosaveKey(this.pageInfo), this.format);
      updateDraft(contentAutosaveKey(this.pageInfo), this.content);
      updateDraft(commitAutosaveKey(this.pageInfo), this.commitMessage);
    },

    clearDrafts() {
      clearDraft(titleAutosaveKey(this.pageInfo));
      clearDraft(formatAutosaveKey(this.pageInfo));
      clearDraft(contentAutosaveKey(this.pageInfo));
      clearDraft(commitAutosaveKey(this.pageInfo));
    },

    handleContentEditorChange({ empty, markdown }) {
      this.contentEditorEmpty = empty;
      this.content = markdown;
    },

    onPageUnload() {
      if (this.isFormDirty) {
        this.updateDrafts();
      } else {
        this.clearDrafts();
      }
    },

    updateCommitMessage() {
      if (!this.title) return;

      // Replace hyphens with spaces
      const newTitle = this.title.replace(/-+/g, ' ').replace('templates/', '');

      const newCommitMessage = sprintf(this.commitMessageI18n, { pageTitle: newTitle }, false);
      this.commitMessage = newCommitMessage;
    },

    notifyContentEditorActive() {
      this.isContentEditorActive = true;
      this.trackContentEditorLoaded();
    },

    notifyContentEditorInactive() {
      this.isContentEditorActive = false;
    },

    trackFormSubmit() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      trackSavedUsingEditor(this.isContentEditorActive, 'Wiki');
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

    trackContentEditorLoaded() {
      this.track(CONTENT_EDITOR_LOADED_ACTION);
    },

    submitFormWithShortcut() {
      this.$refs.form.submit();
    },

    setTemplate(template) {
      this.$refs.markdownEditor.setTemplate(template);
    },
  },
};
</script>

<template>
  <gl-form
    ref="form"
    :action="formAction"
    method="post"
    class="wiki-form common-note-form gl-mt-3 js-quick-submit"
    @submit="handleFormSubmit"
    @input="isFormDirty = true"
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
      <div class="col-12">
        <gl-form-group :label="$options.i18n.title.label" label-for="wiki_title">
          <template v-if="!isTemplate" #description>
            <gl-icon class="gl-mr-n1" name="bulb" />
            {{ titleHelpText }}
            <gl-link :href="helpPath" target="_blank">
              {{ $options.i18n.title.helpText.learnMore }}
            </gl-link>
          </template>
          <gl-form-input
            id="wiki_title"
            v-model="pageTitle"
            type="text"
            class="form-control"
            data-testid="wiki-title-textbox"
            :required="true"
            :autofocus="!pageInfo.persisted"
            :placeholder="titlePlaceholder"
          />
          <input v-model="title" type="hidden" name="wiki[title]" />
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

    <div class="row">
      <div class="col-sm-12 row-sm-5">
        <gl-form-group :label="$options.i18n.content.label" label-for="wiki_content">
          <wiki-template
            v-if="!isTemplate && templates.length"
            :format="format"
            :templates="templates"
            class="gl-mb-4"
            @input="setTemplate"
          />
          <markdown-editor
            ref="markdownEditor"
            v-model="content"
            :form-field-props="formFieldProps"
            :render-markdown-path="pageInfo.markdownPreviewPath"
            :markdown-docs-path="pageInfo.markdownHelpPath"
            :uploads-path="pageInfo.uploadsPath"
            :enable-content-editor="isMarkdownFormat"
            :enable-preview="isMarkdownFormat"
            :autofocus="pageInfo.persisted"
            :enable-autocomplete="true"
            :autocomplete-data-sources="autocompleteDataSources"
            :drawio-enabled="drawioEnabled"
            :disable-attachments="isTemplate"
            @contentEditor="notifyContentEditorActive"
            @markdownField="notifyContentEditorInactive"
            @keydown.ctrl.enter="submitFormWithShortcut"
            @keydown.meta.enter="submitFormWithShortcut"
          />
          <div class="form-text gl-text-gray-600">
            <gl-sprintf
              v-if="displayWikiSpecificMarkdownHelp && !isTemplate"
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
            data-testid="wiki-message-textbox"
            :placeholder="$options.i18n.commitMessage.label"
          />
        </gl-form-group>
      </div>
    </div>

    <div class="gl-display-flex gl-gap-3" data-testid="wiki-form-actions">
      <gl-button
        category="primary"
        variant="confirm"
        type="submit"
        data-testid="wiki-submit-button"
        :disabled="disableSubmitButton"
        >{{ submitButtonText }}</gl-button
      >
      <gl-button
        data-testid="wiki-cancel-button"
        :href="cancelFormPath"
        @click="isFormDirty = false"
      >
        {{ $options.i18n.cancel }}</gl-button
      >
    </div>
  </gl-form>
</template>
