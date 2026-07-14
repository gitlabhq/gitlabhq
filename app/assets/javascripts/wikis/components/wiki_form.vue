<script>
import jsYaml from 'js-yaml';
import { isEmpty } from 'lodash-es';
import {
  GlForm,
  GlButton,
  GlButtonGroup,
  GlCollapsibleListbox,
  GlFormGroup,
  GlFormInput,
  GlFormSelect,
  GlTooltipDirective,
  GlDisclosureDropdown,
  GlModal,
  GlFormTextarea,
  GlToggle,
} from '@gitlab/ui';
import produce from 'immer';
import { getDraft, clearDraft, updateDraft } from '~/lib/utils/autosave';
import csrf from '~/lib/utils/csrf';
import { setUrlFragment } from '~/lib/utils/url_utility';
import { __, s__, sprintf } from '~/locale';
import Tracking from '~/tracking';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { trackSavedUsingEditor } from '~/vue_shared/components/markdown/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import WikiSidebarToggle from '~/wikis/components/wiki_sidebar_toggle.vue';
import { formatDate } from '~/lib/utils/datetime/date_format_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import {
  WIKI_CONTENT_EDITOR_TRACKING_LABEL,
  WIKI_FORMAT_LABEL,
  WIKI_FORMAT_UPDATED_ACTION,
  CONTENT_EDITOR_LOADED_ACTION,
  WIKI_TEMPLATES_DIR,
} from '../constants';
import { isTemplate as isTemplateUrl } from '../utils';
import getAutoCommitMessagePreference from '../graphql/auto_commit_message_preference.query.graphql';
import updateAutoCommitMessagePreference from '../graphql/update_auto_commit_message_preference.mutation.graphql';
import WikiTemplate from './wiki_template.vue';
import DeleteWikiModal from './delete_wiki_modal.vue';

const trackingMixin = Tracking.mixin({
  label: WIKI_CONTENT_EDITOR_TRACKING_LABEL,
});

const SAVE_MESSAGE = {
  AUTO: 'AUTO',
  CUSTOM: 'CUSTOM',
};

const AUTO_GENERATED_PATH_DATE_FORMAT = 'yyyymmddHHMMss';

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
  name: 'WikiForm',
  i18n: {
    title: {
      label: s__('WikiPage|Title'),
      placeholder: s__('WikiPage|Page title'),
      templatePlaceholder: s__('WikiPage|Template title'),
      newPagePlaceholder: s__('WikiPage|{Give this page a title}'),
      defaultTitle: __('Untitled'),
    },
    path: {
      label: s__('WikiPage|Path'),
      placeholder: s__('WikiPage|Page path'),
      description: s__(
        'WikiPage|The path where your page is located. Use "/" to create nested pages.',
      ),
      generateFromTitle: s__('WikiPage|Generate path from title'),
      generateFromTitleHelp: s__(
        'WikiPage|Automatically updates the path when you change the title.',
      ),
      templateTitleHelp: s__(
        'WikiPage|For templates, the path is generated from the title and cannot be edited.',
      ),
      restorePagePath: s__('WikiPage|Convert back to page'),
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
      newSidebar: s__('WikiPage|Create sidebar'),
      newTemplate: s__('WikiPage|Create template'),
      existingTemplate: s__('WikiPage|Save template'),
    },
    cancel: s__('WikiPage|Cancel'),
    messageModalTitle: s__('WikiPage|Add a commit message'),
    autoCommitMessageToggle: s__('WikiPage|Use the default commit message for future saves'),
    autoCommitMessageToggleHelp: s__('WikiPage|Wiki pages save without opening this dialog.'),
    deleteSidebar: s__('WikiPage|Delete sidebar'),
  },
  components: {
    WikiSidebarToggle,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlButton,
    MarkdownEditor,
    WikiTemplate,
    DeleteWikiModal,
    GlButtonGroup,
    GlCollapsibleListbox,
    GlModal,
    GlFormTextarea,
    GlDisclosureDropdown,
    GlToggle,
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
  emits: ['is-editing'],
  saveOptions: [
    {
      text: s__('WikiPage|Save changes directly'),
      description: s__('WikiPage|Uses the default commit message'),
      value: SAVE_MESSAGE.AUTO,
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
      shouldGeneratePathFromTitle:
        (!this.pageInfo.persisted &&
          (!path.startsWith(`${WIKI_TEMPLATES_DIR}/`) || path.endsWith('{new_page_title}'))) ||
        this.isAutoGeneratedPath(path),
      initialPath: path,
      placeholderActive: false,
      placeholderText: this.$options.i18n.title.newPagePlaceholder,
      parentPath: '',
      useAutoCommitMessage: false,
      savingPreference: false,
      commitMessageModalOpen: false,
      isTemplateUrl: isTemplateUrl(),
    };
  },
  apollo: {
    useAutoCommitMessage: {
      query: getAutoCommitMessagePreference,
      update: (data) => {
        return data.currentUser?.userPreferences?.wikiUseAutoCommitMessage ?? false;
      },
    },
  },
  computed: {
    isTemplatePath() {
      return this.path.startsWith(`${WIKI_TEMPLATES_DIR}/`);
    },
    isTemplateByPathOnly() {
      return this.isTemplatePath && !this.isTemplateUrl;
    },
    isTemplate() {
      return this.isTemplateUrl || this.isTemplatePath;
    },
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
    commitMessageI18n() {
      if (this.pageInfo.persisted) {
        if (this.isTemplate) return this.$options.i18n.commitMessage.value.existingTemplate;
        return this.$options.i18n.commitMessage.value.existingPage;
      }
      if (this.isTemplate) return this.$options.i18n.commitMessage.value.newTemplatePage;
      return this.$options.i18n.commitMessage.value.newPage;
    },
    submitButtonText() {
      if (this.isTemplate) {
        return this.pageInfo.persisted
          ? this.$options.i18n.submitButton.existingTemplate
          : this.$options.i18n.submitButton.newTemplate;
      }

      let buttonText = this.pageInfo.persisted
        ? this.$options.i18n.submitButton.existingPage
        : this.$options.i18n.submitButton.newPage;

      buttonText =
        this.isCustomSidebar && !this.pageInfo.persisted
          ? this.$options.i18n.submitButton.newSidebar
          : buttonText;

      return buttonText;
    },
    cancelFormPath() {
      if (this.pageInfo.persisted) return this.pageInfo.path;
      return this.pageInfo.wikiPath;
    },
    contentEditorHelpPath() {
      return setUrlFragment(this.pageInfo.helpPath, 'gitlab-flavored-markdown-support');
    },
    isMarkdownFormat() {
      return this.format === 'markdown';
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
      const serializedFrontMatter =
        this.isTemplate || isEmpty(this.frontMatter)
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
    saveMessageMode() {
      return this.useAutoCommitMessage ? SAVE_MESSAGE.AUTO : SAVE_MESSAGE.CUSTOM;
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
      this.onTitleUpdate();
    },
    shouldGeneratePathFromTitle(newValue) {
      if (newValue) {
        this.generatePathFromTitle();
      }
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
    async submitForm() {
      this.setMissingFields();

      this.isFormDirty = false;

      this.trackFormSubmit();
      this.trackWikiFormat();

      // Wait until form field values are refreshed
      await this.$nextTick();

      this.$refs.form.$el.submit();
    },

    generatePathFromTitle() {
      const prefix = this.isTemplate ? `${WIKI_TEMPLATES_DIR}/` : '';
      this.path = prefix + this.parentPath + this.pageTitle.replace(/ +/g, '-');
    },

    restorePagePath() {
      this.path = this.initialPath.startsWith(`${WIKI_TEMPLATES_DIR}/`)
        ? this.path.replace(new RegExp(`^${WIKI_TEMPLATES_DIR}/`), '')
        : this.initialPath;
    },

    onTitleUpdate() {
      if (!this.placeholderActive) {
        this.frontMatter.title = this.pageTitle;
        this.frontMatter = { ...this.frontMatter };
      }

      if (
        (this.shouldGeneratePathFromTitle || this.isTemplate) &&
        !this.placeholderActive &&
        this.pageTitle !== this.$options.i18n.title.defaultTitle &&
        this.pageTitle.trim().length
      ) {
        this.generatePathFromTitle();
      }
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
      this.$refs.form.$el.submit();
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
      if (this.pageInfo.persisted) return;

      if (!this.pageTitle.endsWith('{new_page_title}')) return;

      this.parentPath = this.pageTitle.replace(/\{new_page_title\}$/, '');

      this.pageTitle = this.placeholderText;
      if (this.shouldGeneratePathFromTitle) {
        this.path = this.parentPath;
      }

      this.placeholderActive = true;

      await this.$nextTick();
      this.positionCursorForPlaceholder();
    },

    positionCursorForPlaceholder() {
      const input = this.$refs.titleInput?.$el || this.$refs.titleInput;
      if (input) {
        input.setSelectionRange(0, 0);
        input.focus();
      }
    },

    handleTitleInput(event) {
      const newValue = (event.target ? event.target.value : event).replace(
        /[\r\n\u2028\u2029]/g,
        ' ',
      );

      if (this.placeholderActive) {
        // Check if user has modified the placeholder area
        if (!newValue.includes(this.placeholderText)) {
          this.placeholderActive = false;
        }
      }

      this.pageTitle = newValue;
    },

    async handleTitleKeydown(event) {
      if (event.key === 'Enter') {
        event.preventDefault();
        return;
      }

      if (this.placeholderActive && this.isPrintableKey(event)) {
        this.placeholderActive = false;
        this.pageTitle = '';
        await this.$nextTick();
        const input = this.$refs.titleInput?.$el || this.$refs.titleInput;
        if (input) {
          input.setSelectionRange(0, 0);
        }
      }
    },

    handleTitleFocus() {
      if (this.placeholderActive) {
        this.positionCursorForPlaceholder();
      }
    },

    validateTitle() {
      this.isTitleValid = Boolean(this.pageTitle.trim().length > 0);
    },

    setAutoGeneratedTitle() {
      this.pageTitle = this.$options.i18n.title.defaultTitle;
    },

    setAutoGeneratedPath() {
      const dateSegment = formatDate(Date.now(), AUTO_GENERATED_PATH_DATE_FORMAT);
      const prefix = this.isTemplate ? `${WIKI_TEMPLATES_DIR}/` : '';
      this.path = `${prefix}untitled-${dateSegment}`;
    },

    isAutoGeneratedPath(path) {
      const regex = new RegExp(`^(${WIKI_TEMPLATES_DIR}/)?untitled-\\d{14}$`);
      return regex.test(path);
    },

    setMissingFields() {
      // Ensure empty string with spaces don't prevent the placeholder from being shown
      this.pageTitle = this.pageTitle.trim();

      if (!this.pageTitle.trim().length) {
        this.setAutoGeneratedTitle();
      }
      if (!this.path.trim().length || (this.isTemplate && this.isAutoGeneratedPath(this.path))) {
        this.setAutoGeneratedPath();
      }
    },

    handleSave() {
      if (this.useAutoCommitMessage) {
        this.submitForm();
      } else {
        this.commitMessageModalOpen = true;
      }
    },

    async handleSaveMessageModeSelect(value) {
      const useAutoCommitMessage = value === SAVE_MESSAGE.AUTO;
      if (this.useAutoCommitMessage !== useAutoCommitMessage) {
        this.useAutoCommitMessage = useAutoCommitMessage;
        await this.updateCommitMessageModePreference(useAutoCommitMessage);
      }
      this.handleSave();
    },

    async updateCommitMessageModePreference(useAutoCommitMessage) {
      try {
        this.savingPreference = true;
        await this.$apollo.mutate({
          mutation: updateAutoCommitMessagePreference,
          variables: {
            input: {
              wikiUseAutoCommitMessage: useAutoCommitMessage,
            },
          },
          optimisticResponse: {
            userPreferencesUpdate: {
              __typename: 'UserPreferencesUpdatePayload',
              userPreferences: {
                __typename: 'UserPreferences',
                wikiUseAutoCommitMessage: useAutoCommitMessage,
              },
            },
          },
          update(cache, { data: { userPreferencesUpdate } }) {
            cache.updateQuery({ query: getAutoCommitMessagePreference }, (existingData) =>
              produce(existingData, (draft) => {
                if (draft?.currentUser?.userPreferences) {
                  draft.currentUser.userPreferences.wikiUseAutoCommitMessage =
                    userPreferencesUpdate.userPreferences.wikiUseAutoCommitMessage;
                }
              }),
            );
          },
        });
      } catch (e) {
        Sentry.captureException();
      } finally {
        this.savingPreference = false;
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
    @submit.prevent="handleSave"
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
    <input :value="commitMessage" name="wiki[message]" type="hidden" />
    <input v-if="isCustomSidebar" value="_sidebar" name="wiki[title]" type="hidden" />

    <div class="row">
      <div class="gl-col-sm-12 row-sm-5">
        <gl-form-group :label="$options.i18n.content.label" label-for="wiki_content" label-sr-only>
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
            immersive
            @contentEditor="notifyContentEditorActive"
            @markdownField="notifyContentEditorInactive"
            @keydown.ctrl.enter="submitFormWithShortcut"
            @keydown.meta.enter="submitFormWithShortcut"
          >
            <template #header>
              <div
                class="gl-flex gl-items-start gl-bg-default gl-px-5 gl-pt-3"
                data-testid="wiki-form-actions"
              >
                <div class="toggle-with-hide-transition gl-my-2 gl-shrink-0 gl-p-2">
                  <wiki-sidebar-toggle action="open" />
                </div>
                <div
                  class="flexible-input-container gl-my-2 gl-flex gl-items-start gl-gap-2 gl-overflow-hidden gl-p-2"
                >
                  <h1 v-if="isCustomSidebar" class="gl-heading-3 !gl-mb-0 md:gl-heading-2">
                    {{
                      pageInfo.persisted
                        ? s__('Wiki|Edit Sidebar')
                        : s__('Wiki|Create custom sidebar')
                    }}
                  </h1>
                  <textarea
                    v-else
                    id="wiki_title"
                    ref="titleInput"
                    v-model="pageTitle"
                    class="flexible-input gl-heading-3 !gl-mb-0 gl-max-h-[4lh] gl-flex-1 gl-resize-none gl-overflow-x-hidden gl-overflow-y-scroll gl-rounded-md gl-border-none gl-bg-transparent gl-shadow-none md:gl-heading-2"
                    data-testid="wiki-title-textbox"
                    required
                    :autofocus="!pageInfo.persisted"
                    :placeholder="titlePlaceholder"
                    :aria-label="titlePlaceholder"
                    @input="handleTitleInput"
                    @keydown="handleTitleKeydown"
                    @focus="handleTitleFocus"
                  ></textarea>
                  <gl-disclosure-dropdown
                    icon="chevron-down"
                    :toggle-text="s__('Wiki|Edit page options')"
                    text-sr-only
                    category="tertiary"
                    no-caret
                    fluid-width
                  >
                    <div class="gl-min-w-md gl-w-md gl-flex gl-flex-col !gl-p-5">
                      <gl-form-group
                        v-if="!isCustomSidebar"
                        :label="$options.i18n.path.label"
                        label-for="wiki_path"
                        :description="isTemplate ? null : $options.i18n.path.description"
                      >
                        <gl-form-input
                          id="wiki_path"
                          v-model="path"
                          name="wiki[title]"
                          data-testid="wiki-path-textbox"
                          class="form-control !gl-font-monospace"
                          :required="true"
                          :readonly="isTemplate"
                          :placeholder="$options.i18n.path.placeholder"
                        />
                        <template v-if="isTemplate" #description>
                          {{ $options.i18n.path.templateTitleHelp }}
                          <gl-button
                            v-if="isTemplateByPathOnly"
                            variant="link"
                            class="gl-align-baseline"
                            data-testid="convert-to-page-button"
                            @click="restorePagePath"
                            >{{ $options.i18n.path.restorePagePath }}</gl-button
                          >
                        </template>
                      </gl-form-group>
                      <gl-toggle
                        v-if="!isCustomSidebar && !isTemplate"
                        v-model="shouldGeneratePathFromTitle"
                        :label="$options.i18n.path.generateFromTitle"
                        :help="$options.i18n.path.generateFromTitleHelp"
                        label-position="top"
                        label-id="lock-path"
                        class="gl-mb-5"
                        data-testid="path-generation-toggle"
                      />
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
                <div class="gl-grow"></div>
                <div class="gl-my-3 gl-flex gl-shrink-0 gl-gap-3">
                  <gl-button-group>
                    <gl-button
                      variant="confirm"
                      type="submit"
                      :loading="savingPreference"
                      data-testid="wiki-submit-button"
                      @click.prevent="handleSave"
                      >{{ submitButtonText }}</gl-button
                    >
                    <gl-collapsible-listbox
                      :selected="saveMessageMode"
                      :items="$options.saveOptions"
                      toggle-text="s__('Wiki|Save and choose commit message')"
                      variant="confirm"
                      data-testid="wiki-submit-message-mode"
                      text-sr-only
                      @select="handleSaveMessageModeSelect"
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
                  <delete-wiki-modal v-if="isCustomSidebar || isTemplate" />
                </div>
              </div>
            </template>
          </markdown-editor>
          <input name="wiki[content]" type="hidden" :value="rawContent" />
        </gl-form-group>
      </div>
    </div>

    <gl-modal
      v-model="commitMessageModalOpen"
      modal-id="commit-message-modal"
      data-testid="commit-message-modal"
      :title="$options.i18n.messageModalTitle"
      :action-primary="messageModalAction.primary"
      :action-cancel="messageModalAction.cancel"
      @primary="submitForm"
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
      <gl-toggle
        :value="useAutoCommitMessage"
        :label="$options.i18n.autoCommitMessageToggle"
        :help="$options.i18n.autoCommitMessageToggleHelp"
        :disabled="savingPreference"
        label-position="left"
        data-testid="auto-commit-message-toggle"
        @change="updateCommitMessageModePreference"
      />
    </gl-modal>
  </gl-form>
</template>
