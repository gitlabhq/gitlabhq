<script>
import jsYaml from 'js-yaml';
import { isEmpty } from 'lodash';
import {
  GlForm,
  GlLink,
  GlButton,
  GlSprintf,
  GlFormGroup,
  GlFormCheckbox,
  GlFormInput,
  GlFormSelect,
} from '@gitlab/ui';
import { getDraft, clearDraft, updateDraft } from '~/lib/utils/autosave';
import csrf from '~/lib/utils/csrf';
import { setUrlFragment } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';
import Tracking from '~/tracking';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  WIKI_CONTENT_EDITOR_TRACKING_LABEL,
  WIKI_FORMAT_LABEL,
  WIKI_FORMAT_UPDATED_ACTION,
  CONTENT_EDITOR_LOADED_ACTION,
} from '../constants';
import { isTemplate } from '../utils';
import WikiTemplate from './wiki_template.vue';
import DeleteWikiModal from './delete_wiki_modal.vue';

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

const getTitle = (pageInfo, frontMatter) => {
  const autosavedTitle = getDraft(titleAutosaveKey(pageInfo));
  const frontMatterTitle = frontMatter?.title?.trim();
  const pageInfoTitle = pageInfo.title?.trim();

  return autosavedTitle || frontMatterTitle || pageInfoTitle || '';
};

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
    path: {
      label: s__('WikiPage|Path'),
      placeholder: s__('WikiPage|Page path'),
    },
    format: {
      label: s__('WikiPage|Format'),
    },
    template: {
      label: __('Template'),
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
      newSidebar: s__('WikiPage|Create custom sidebar'),
      newTemplate: s__('WikiPage|Create template'),
    },
    cancel: s__('WikiPage|Cancel'),
  },
  components: {
    GlForm,
    GlFormGroup,
    GlFormCheckbox,
    GlFormInput,
    GlFormSelect,
    GlSprintf,
    GlLink,
    GlButton,
    MarkdownEditor,
    WikiTemplate,
    DeleteWikiModal,
  },
  mixins: [trackingMixin, glFeatureFlagsMixin()],
  inject: [
    'isEditingPath',
    'formatOptions',
    'pageInfo',
    'drawioUrl',
    'templates',
    'pageHeading',
    'wikiUrl',
  ],
  data() {
    const title = window.location.href.includes('random_title=true')
      ? ''
      : getTitle(this.pageInfo, this.pageInfo.frontMatter);
    const path = window.location.href.includes('random_title=true') ? '' : this.pageInfo.slug;
    return {
      editingMode: 'source',
      title,
      pageTitle: title.replace('templates/', ''),
      format: getFormat(this.pageInfo),
      path,
      frontMatter: this.pageInfo.frontMatter || {},
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
        class: 'note-textarea',
      },
      generatePathFromTitle: !this.pageInfo.persisted,
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
      let buttonText = this.pageInfo.persisted
        ? this.$options.i18n.submitButton.existingPage
        : this.$options.i18n.submitButton.newPage;

      buttonText =
        this.isCustomSidebar && !this.pageInfo.persisted
          ? this.$options.i18n.submitButton.newSidebar
          : buttonText;

      return buttonText;
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
    drawioEnabled() {
      return typeof this.drawioUrl === 'string' && this.drawioUrl.length > 0;
    },
    cancelFormHref() {
      if (this.isEditingPath) {
        return this.cancelFormPath;
      }

      return null;
    },
    isCustomSidebar() {
      return this.wikiUrl.endsWith('_sidebar');
    },
    rawContent() {
      const serializedFrontMatter = isEmpty(this.frontMatter)
        ? ''
        : `---\n${jsYaml.safeDump(this.frontMatter, { skipInvalid: true })}---\n`;

      return `${serializedFrontMatter}${this.content}`;
    },
  },
  watch: {
    title() {
      this.updateCommitMessage();
    },
    pageTitle() {
      this.title =
        this.isTemplate && !this.pageInfo.persisted
          ? `templates/${this.pageTitle}`
          : this.pageTitle;
      this.updateFrontMatterTitle();
    },
    generatePathFromTitle() {
      this.updateFrontMatterTitle();
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

    updateFrontMatterTitle() {
      if (this.generatePathFromTitle) {
        delete this.frontMatter.title;
        this.path = this.title.replace(/ +/g, '-');
      } else {
        this.frontMatter.title = this.pageTitle;
        if (this.pageInfo.persisted) {
          this.path = this.pageInfo.slug;
        }
      }

      this.frontMatter = { ...this.frontMatter };
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
      let newTitle = this.title.replace(/-+/g, ' ').replace('templates/', '');

      // Replace _sidebar with sidebar
      if (this.isCustomSidebar) {
        newTitle = this.title.replace('_sidebar', 'sidebar');
      }

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
    cancelFormAction() {
      this.isFormDirty = false;

      if (!this.isEditingPath) {
        this.$emit('is-editing', false);
      }
    },
  },
};
</script>

<template>
  <gl-form
    ref="form"
    :action="formAction"
    method="post"
    class="wiki-form common-note-form js-quick-submit"
    :class="{ 'gl-mt-5': !isEditingPath }"
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
        <gl-form-group
          :label="$options.i18n.title.label"
          label-for="wiki_title"
          :class="{ 'gl-hidden': isCustomSidebar }"
        >
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
        </gl-form-group>
      </div>

      <div class="col-12">
        <gl-form-group :label="$options.i18n.path.label" label-for="wiki_path">
          <gl-form-input
            id="wiki_path"
            v-model="path"
            name="wiki[title]"
            data-testid="wiki-path-textbox"
            type="text"
            class="form-control !gl-font-monospace"
            :required="true"
            :readonly="generatePathFromTitle"
            :placeholder="$options.i18n.path.placeholder"
          />
          <gl-form-checkbox v-model="generatePathFromTitle" class="gl-mt-3 gl-pt-2">{{
            __('Generate page path from title')
          }}</gl-form-checkbox>
        </gl-form-group>
      </div>
    </div>

    <div class="row">
      <div class="col-sm-6">
        <gl-form-group :label="$options.i18n.format.label" label-for="wiki_format">
          <gl-form-select
            id="wiki_format"
            v-model="format"
            name="wiki[format]"
            :disabled="isContentEditorActive"
            :value="formatOptions.Markdown"
          >
            <option v-for="(key, label) of formatOptions" :key="key" :value="key">
              {{ label }}
            </option>
          </gl-form-select>
        </gl-form-group>
      </div>
      <div v-if="!isTemplate" class="col-sm-6">
        <gl-form-group :label="$options.i18n.template.label" label-for="wiki_template">
          <wiki-template :format="format" :templates="templates" @input="setTemplate" />
        </gl-form-group>
      </div>
    </div>

    <div class="row">
      <div class="col-sm-12 row-sm-5">
        <gl-form-group :label="$options.i18n.content.label" label-for="wiki_content">
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
          <input name="wiki[content]" type="hidden" :value="rawContent" />
          <template #description>
            <div class="gl-mt-3">
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
          </template>
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

    <div class="gl-flex gl-justify-between gl-gap-3" data-testid="wiki-form-actions">
      <div class="gl-flex gl-gap-3">
        <gl-button
          category="primary"
          variant="confirm"
          type="submit"
          data-testid="wiki-submit-button"
          >{{ submitButtonText }}</gl-button
        >
        <gl-button
          data-testid="wiki-cancel-button"
          :href="cancelFormHref"
          @click="cancelFormAction"
        >
          {{ $options.i18n.cancel }}</gl-button
        >
      </div>
      <delete-wiki-modal />
    </div>
  </gl-form>
</template>
