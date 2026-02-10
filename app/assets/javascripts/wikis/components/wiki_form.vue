<script>
import jsYaml from 'js-yaml';
import { isEmpty } from 'lodash';
import {
  GlForm,
  GlLink,
  GlButton,
  GlButtonGroup,
  GlCollapsibleListbox,
  GlSprintf,
  GlFormGroup,
  GlFormCheckbox,
  GlFormInput,
  GlFormSelect,
  GlTooltipDirective,
  GlDisclosureDropdown,
  GlModal,
  GlFormTextarea,
} from '@gitlab/ui';
import { getDraft, clearDraft, updateDraft } from '~/lib/utils/autosave';
import csrf from '~/lib/utils/csrf';
import { setUrlFragment } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import Tracking from '~/tracking';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import WikiSidebarToggle from '~/wikis/components/wiki_sidebar_toggle.vue';
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

const SAVE_MESSAGE = {
  DEFAULT: 'DEFAULT',
  CUSTOM: 'CUSTOM',
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
      newPagePlaceholder: s__('WikiPage|{Give this page a title}'),
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
      'WikiPage|To link to a (new) page, type %{linkExample}. %{linkStart}What types of links are supported?%{linkEnd}',
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
    messageModalTitle: s__('WikiPage|Add a commit message'),
  },
  components: {
    WikiSidebarToggle,
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
    GlButtonGroup,
    GlCollapsibleListbox,
    GlModal,
    GlFormTextarea,
    LocalStorageSync,
    GlDisclosureDropdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
  saveOptions: [
    {
      text: s__('WikiPage|Save changes directly'),
      description: s__('WikiPage|Uses the default commit message'),
      value: SAVE_MESSAGE.DEFAULT,
    },
    {
      text: s__('WikiPage|Save changes with message'),
      description: s__('WikiPage|Review and write a commit message'),
      value: SAVE_MESSAGE.CUSTOM,
    },
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
      isTitleValid: null,
      formFieldProps: {
        placeholder: this.$options.i18n.content.placeholder,
        'aria-label': this.$options.i18n.content.label,
        id: 'wiki_content',
        class: 'note-textarea',
      },
      generatePathFromTitle: !this.pageInfo.persisted,
      placeholderActive: false,
      placeholderText: this.$options.i18n.title.newPagePlaceholder,
      parentPath: '',
      initialTitleValue: '',
      saveMessageMode: SAVE_MESSAGE.DEFAULT,
      commitMessageModalOpen: false,
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
      return helpPagePath('user/project/wiki/markdown', { anchor: 'links' });
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
    messageModalAction() {
      return {
        primary: { text: this.submitButtonText },
        cancel: { text: this.$options.i18n.cancel },
      };
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
    this.initializeTitlePlaceholder();

    if (!this.commitMessage) this.updateCommitMessage();
    window.addEventListener('beforeunload', this.onPageUnload);
  },
  destroyed() {
    window.removeEventListener('beforeunload', this.onPageUnload);
  },
  methods: {
    async handleFormSubmit(e) {
      this.isFormDirty = false;

      e?.preventDefault();

      this.validateTitle();

      if (!this.isTitleValid) {
        return;
      }

      this.trackFormSubmit();
      this.trackWikiFormat();

      // Wait until form field values are refreshed
      await this.$nextTick();

      this.$refs.form.$el.submit();
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
    isPrintableKey(event) {
      // More robust check for printable characters
      // Excludes control keys, function keys, etc.
      if (event.ctrlKey || event.metaKey || event.altKey) {
        return false;
      }

      // Check if it's a single printable character
      // This includes letters, numbers, symbols, space, etc.
      const { key } = event;
      return key.length === 1;
    },
    async initializeTitlePlaceholder() {
      if (!this.pageInfo.persisted) {
        this.initialTitleValue = this.pageTitle;

        if (this.initialTitleValue.endsWith('{new_page_title}')) {
          // Extract parent path by removing the placeholder
          this.parentPath = this.initialTitleValue.replace(/\{new_page_title\}$/, '');

          // Set the title with placeholder text
          this.pageTitle = `${this.parentPath}${this.placeholderText}`;
          this.placeholderActive = true;

          // Position cursor after parent path on next tick
          await this.$nextTick();
          this.positionCursorAfterParentPath();
        }
      }
    },

    positionCursorAfterParentPath() {
      const input = this.$refs.titleInput?.$el || this.$refs.titleInput;
      if (input) {
        const cursorPosition = this.parentPath.length;
        input.setSelectionRange(cursorPosition, cursorPosition);
        input.focus();
      }
    },

    handleTitleInput(event) {
      const newValue = event.target ? event.target.value : event;

      if (this.placeholderActive) {
        // Check if user has modified the placeholder area
        if (!newValue.includes(this.placeholderText)) {
          this.placeholderActive = false;
        }
      }

      this.pageTitle = newValue;
    },

    async handleTitleKeydown(event) {
      if (this.placeholderActive && this.isPrintableKey(event)) {
        // Clear the placeholder
        this.placeholderActive = false;
        this.pageTitle = this.parentPath;

        // Position cursor at the end
        await this.$nextTick();
        const input = this.$refs.titleInput?.$el || this.$refs.titleInput;
        if (input) {
          input.setSelectionRange(this.parentPath.length, this.parentPath.length);
        }
      }
    },

    handleTitleFocus() {
      if (this.placeholderActive) {
        this.positionCursorAfterParentPath();
      }
    },
    validateTitle() {
      this.isTitleValid = Boolean(this.pageTitle.trim().length > 0);
    },
    handleSave() {
      if (this.saveMessageMode === SAVE_MESSAGE.CUSTOM) {
        this.commitMessageModalOpen = true;
      } else {
        this.$refs.form.$el.submit();
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
    :class="{
      'gl-mt-5': !isEditingPath && !glFeatures.wikiImmersiveEditor,
      immersive: glFeatures.wikiImmersiveEditor,
    }"
    @submit="handleFormSubmit"
    @input="isFormDirty = true"
  >
    <h1 v-if="!glFeatures.wikiImmersiveEditor" class="gl-sr-only">
      {{ pageTitle }}
    </h1>
    <input :value="csrfToken" type="hidden" name="authenticity_token" />
    <input v-if="pageInfo.persisted" type="hidden" name="_method" value="put" />
    <input
      :v-if="pageInfo.persisted"
      type="hidden"
      name="wiki[last_commit_sha]"
      :value="pageInfo.lastCommitSha"
    />
    <input
      v-if="glFeatures.wikiImmersiveEditor"
      :value="commitMessage"
      name="wiki[message]"
      type="hidden"
    />
    <local-storage-sync
      v-if="glFeatures.wikiImmersiveEditor"
      v-model="saveMessageMode"
      storage-key="wiki_save_message_mode"
    />

    <div v-if="!glFeatures.wikiImmersiveEditor" class="row">
      <div class="gl-col-12">
        <gl-form-group
          :label="$options.i18n.title.label"
          label-for="wiki_title"
          :class="{ 'gl-hidden': isCustomSidebar }"
          :invalid-feedback="__('A title is required')"
        >
          <gl-form-input
            id="wiki_title"
            ref="titleInput"
            v-model="pageTitle"
            type="text"
            class="form-control"
            data-testid="wiki-title-textbox"
            :required="true"
            :autofocus="!pageInfo.persisted"
            :placeholder="titlePlaceholder"
            :state="isTitleValid"
            @input="handleTitleInput"
            @keydown="handleTitleKeydown"
            @focus="handleTitleFocus"
            @blur="validateTitle"
          />
        </gl-form-group>
      </div>

      <div class="gl-col-12">
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

    <div v-if="!glFeatures.wikiImmersiveEditor" class="row">
      <div class="gl-col-sm-6">
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
      <div v-if="!isTemplate" class="gl-col-sm-6">
        <gl-form-group :label="$options.i18n.template.label" label-for="wiki_template">
          <wiki-template :format="format" :templates="templates" @input="setTemplate" />
        </gl-form-group>
      </div>
    </div>

    <div class="row">
      <div class="gl-col-sm-12 row-sm-5">
        <gl-form-group
          :label="$options.i18n.content.label"
          label-for="wiki_content"
          :label-sr-only="glFeatures.wikiImmersiveEditor"
        >
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
            supports-table-of-contents
            :disable-attachments="isTemplate"
            :immersive="glFeatures.wikiImmersiveEditor"
            @contentEditor="notifyContentEditorActive"
            @markdownField="notifyContentEditorInactive"
            @keydown.ctrl.enter="submitFormWithShortcut"
            @keydown.meta.enter="submitFormWithShortcut"
          >
            <template v-if="glFeatures.wikiImmersiveEditor" #header>
              <div
                class="gl-flex gl-items-start gl-gap-3 gl-bg-default gl-px-5 gl-pt-3"
                data-testid="wiki-form-actions"
              >
                <wiki-sidebar-toggle action="open" class="gl-my-2 gl-shrink-0" />
                <div
                  class="flexible-input-container gl-flex gl-items-center gl-gap-2 gl-overflow-hidden gl-p-2"
                >
                  <h1 v-if="isCustomSidebar" class="gl-heading-3 !gl-mb-0 md:gl-heading-2">
                    {{ s__('Wiki|Edit Sidebar') }}
                  </h1>
                  <input
                    v-else
                    id="wiki_title"
                    ref="titleInput"
                    v-model="pageTitle"
                    class="flexible-input gl-heading-3 !gl-mb-0 gl-flex-1 gl-overflow-hidden gl-rounded-md gl-border-none gl-bg-transparent gl-shadow-none md:gl-heading-2"
                    data-testid="wiki-title-textbox"
                    required
                    :autofocus="!pageInfo.persisted"
                    :placeholder="titlePlaceholder"
                    :aria-label="titlePlaceholder"
                    :state="isTitleValid"
                    @input="handleTitleInput"
                    @keydown="handleTitleKeydown"
                    @focus="handleTitleFocus"
                    @blur="validateTitle"
                  />
                  <gl-disclosure-dropdown
                    icon="chevron-down"
                    :toggle-text="s__('Wiki|Edit page options')"
                    text-sr-only
                    category="tertiary"
                    no-caret
                  >
                    <div class="p-3 gl-min-w-md">
                      <gl-form-group
                        v-if="!isCustomSidebar"
                        :label="$options.i18n.path.label"
                        label-for="wiki_path"
                      >
                        <gl-form-input
                          id="wiki_path"
                          v-model="path"
                          name="wiki[title]"
                          data-testid="wiki-path-textbox"
                          class="form-control !gl-font-monospace"
                          :required="true"
                          :readonly="generatePathFromTitle"
                          :placeholder="$options.i18n.path.placeholder"
                        />
                        <gl-form-checkbox v-model="generatePathFromTitle" class="gl-mt-3 gl-pt-2">{{
                          __('Generate page path from title')
                        }}</gl-form-checkbox>
                      </gl-form-group>
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
                      <gl-form-group
                        v-if="!isTemplate"
                        :label="$options.i18n.template.label"
                        label-for="wiki_template"
                        class="gl-mb-0"
                      >
                        <wiki-template
                          :format="format"
                          :templates="templates"
                          @input="setTemplate"
                        />
                      </gl-form-group>
                    </div>
                  </gl-disclosure-dropdown>
                </div>
                <div class="gl-flex-grow"></div>
                <div class="gl-my-3 gl-flex gl-shrink-0 gl-gap-3">
                  <gl-button-group>
                    <gl-button
                      variant="confirm"
                      type="submit"
                      data-testid="wiki-submit-button"
                      @click.prevent="handleSave"
                      >{{ submitButtonText }}</gl-button
                    >
                    <gl-collapsible-listbox
                      v-model="saveMessageMode"
                      :items="$options.saveOptions"
                      toggle-text="s__('Wiki|Save and choose commit message')"
                      variant="confirm"
                      data-testid="wiki-submit-message-mode"
                      text-sr-only
                      @select="handleSave"
                    >
                      <template #list-item="{ item }">
                        <div class="gl-whitespace-nowrap gl-font-bold">{{ item.text }}</div>
                        <div class="gl-text-subtle">{{ item.description }}</div>
                      </template>
                    </gl-collapsible-listbox>
                  </gl-button-group>
                  <gl-button
                    data-testid="wiki-cancel-button"
                    :href="cancelFormHref"
                    @click="cancelFormAction"
                  >
                    {{ $options.i18n.cancel }}</gl-button
                  >
                </div>
              </div>
            </template>
          </markdown-editor>
          <input name="wiki[content]" type="hidden" :value="rawContent" />
          <template v-if="!glFeatures.wikiImmersiveEditor" #description>
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

    <div v-if="!glFeatures.wikiImmersiveEditor" class="row">
      <div class="gl-col-sm-12 row-sm-5">
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

    <div
      v-if="!glFeatures.wikiImmersiveEditor"
      class="gl-flex gl-justify-between gl-gap-3"
      data-testid="wiki-form-actions"
    >
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

    <gl-modal
      v-if="glFeatures.wikiImmersiveEditor"
      v-model="commitMessageModalOpen"
      modal-id="commit-message-modal"
      data-testid="commit-message-modal"
      :title="$options.i18n.messageModalTitle"
      :action-primary="messageModalAction.primary"
      :action-cancel="messageModalAction.cancel"
      @primary="handleFormSubmit"
    >
      <gl-form-group
        :label="$options.i18n.commitMessage.label"
        label-for="wiki_message"
        label-sr-only
      >
        <gl-form-textarea
          id="wiki_message"
          v-model.trim="commitMessage"
          class="form-control"
          data-testid="wiki-message-textbox"
          :placeholder="$options.i18n.commitMessage.label"
        />
      </gl-form-group>
    </gl-modal>
  </gl-form>
</template>
