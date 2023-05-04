<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import $ from 'jquery';
import { debounce, unescape } from 'lodash';
import { createAlert } from '~/alert';
import GLForm from '~/gl_form';
import SafeHtml from '~/vue_shared/directives/safe_html';
import axios from '~/lib/utils/axios_utils';
import { stripHtml } from '~/lib/utils/text_utility';
import { __, sprintf } from '~/locale';
import Suggestions from '~/vue_shared/components/markdown/suggestions.vue';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import MarkdownHeader from './header.vue';
import MarkdownToolbar from './toolbar.vue';

function cleanUpLine(content) {
  return unescape(stripHtml(content).replace(/\\n/g, '%br').replace(/\n/g, ''));
}

export default {
  components: {
    MarkdownHeader,
    MarkdownToolbar,
    GlIcon,
    Suggestions,
  },
  directives: {
    SafeHtml,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    /**
     * This prop should be bound to the value of the `<textarea>` element
     * that is rendered as a child of this component (in the `textarea` slot)
     */
    textareaValue: {
      type: String,
      required: true,
    },
    markdownDocsPath: {
      type: String,
      required: true,
    },
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
    markdownPreviewPath: {
      type: String,
      required: false,
      default: '',
    },
    enablePreview: {
      type: Boolean,
      required: false,
      default: true,
    },
    addSpacingClasses: {
      type: Boolean,
      required: false,
      default: true,
    },
    quickActionsDocsPath: {
      type: String,
      required: false,
      default: '',
    },
    canAttachFile: {
      type: Boolean,
      required: false,
      default: true,
    },
    uploadsPath: {
      type: String,
      required: false,
      default: '',
    },
    enableAutocomplete: {
      type: Boolean,
      required: false,
      default: true,
    },
    autocompleteDataSources: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    line: {
      type: Object,
      required: false,
      default: null,
    },
    lines: {
      type: Array,
      required: false,
      default: () => [],
    },
    note: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    canSuggest: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
    showSuggestPopover: {
      type: Boolean,
      required: false,
      default: false,
    },
    showCommentToolBar: {
      type: Boolean,
      required: false,
      default: true,
    },
    restrictedToolBarItems: {
      type: Array,
      required: false,
      default: () => [],
    },
    showContentEditorSwitcher: {
      type: Boolean,
      required: false,
      default: false,
    },
    drawioEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      markdownPreview: '',
      referencedCommands: '',
      referencedUsers: [],
      hasSuggestion: false,
      markdownPreviewLoading: false,
      previewMarkdown: false,
      suggestions: this.note.suggestions || [],
      debouncedFetchMarkdownLoading: false,
    };
  },
  computed: {
    shouldShowReferencedUsers() {
      const referencedUsersThreshold = 10;
      return this.referencedUsers.length >= referencedUsersThreshold;
    },
    lineContent() {
      if (this.lines.length) {
        return this.lines
          .map((line) => {
            const { rich_text: richText, text } = line;

            if (text) {
              return text;
            }

            return cleanUpLine(richText);
          })
          .join('\\n');
      }

      if (this.line) {
        const { rich_text: richText, text } = this.line;

        if (text) {
          return text;
        }

        return cleanUpLine(richText);
      }

      return '';
    },
    lineNumber() {
      let lineNumber;
      if (this.line) {
        const { new_line: newLine, old_line: oldLine } = this.line;
        lineNumber = newLine || oldLine;
      }
      return lineNumber;
    },
    lineType() {
      return this.line ? this.line.type : '';
    },
    addMultipleToDiscussionWarning() {
      return sprintf(
        __(
          'You are about to add %{usersTag} people to the discussion. They will all receive a notification.',
        ),
        {
          usersTag: `<strong><span class="js-referenced-users-count">${this.referencedUsers.length}</span></strong>`,
        },
        false,
      );
    },
    suggestionsStartIndex() {
      return Math.max(this.lines.length - 1, 0);
    },
  },
  watch: {
    isSubmitting(isSubmitting) {
      if (!isSubmitting || !this.$refs['markdown-preview'].querySelectorAll) {
        return;
      }
      const mediaInPreview = this.$refs['markdown-preview'].querySelectorAll('video, audio');

      if (mediaInPreview) {
        mediaInPreview.forEach((media) => {
          media.pause();
        });
      }
    },

    textareaValue: {
      immediate: true,
      handler(textareaValue, oldVal) {
        const all = /@all([^\w._-]|$)/;
        const hasAll = all.test(textareaValue);
        const hadAll = all.test(oldVal);

        const justAddedAll = !hadAll && hasAll;
        const justRemovedAll = hadAll && !hasAll;

        if (justAddedAll) {
          this.debouncedFetchMarkdownLoading = false;
          this.debouncedFetchMarkdown();
        } else if (justRemovedAll) {
          this.debouncedFetchMarkdownLoading = true;
          this.referencedUsers = [];
        }
      },
    },
    enablePreview: {
      immediate: true,
      handler(newVal) {
        if (!newVal) {
          this.hidePreview();
        }
      },
    },
  },
  mounted() {
    // GLForm class handles all the toolbar buttons
    return new GLForm(
      $(this.$refs['gl-form']),
      {
        emojis: this.enableAutocomplete,
        members: this.enableAutocomplete,
        issues: this.enableAutocomplete,
        mergeRequests: this.enableAutocomplete,
        epics: this.enableAutocomplete,
        milestones: this.enableAutocomplete,
        labels: this.enableAutocomplete,
        snippets: this.enableAutocomplete,
        vulnerabilities: this.enableAutocomplete,
        contacts: this.enableAutocomplete,
      },
      true,
      this.autocompleteDataSources,
    );
  },
  beforeDestroy() {
    const glForm = $(this.$refs['gl-form']).data('glForm');
    if (glForm) {
      glForm.destroy();
    }
  },
  methods: {
    showPreview() {
      if (this.previewMarkdown) return;

      this.previewMarkdown = true;

      if (this.textareaValue) {
        this.markdownPreviewLoading = true;
        this.markdownPreview = __('Loading…');

        this.fetchMarkdown()
          .then((data) => this.renderMarkdown(data))
          .catch(() =>
            createAlert({
              message: __('Error loading markdown preview'),
            }),
          );
      } else {
        this.renderMarkdown();
      }
    },
    hidePreview() {
      this.markdownPreview = '';
      this.previewMarkdown = false;
    },

    fetchMarkdown() {
      return axios.post(this.markdownPreviewPath, { text: this.textareaValue }).then(({ data }) => {
        const { references } = data;
        if (references) {
          this.referencedCommands = references.commands;
          this.referencedUsers = references.users;
          this.hasSuggestion = references.suggestions?.length > 0;
          this.suggestions = references.suggestions;
        }

        return data;
      });
    },

    debouncedFetchMarkdown: debounce(function debouncedFetchMarkdown() {
      return this.fetchMarkdown().then(() => {
        if (this.debouncedFetchMarkdownLoading) {
          this.referencedUsers = [];
          this.debouncedFetchMarkdownLoading = false;
        }
      });
    }, 400),

    renderMarkdown(data = {}) {
      this.markdownPreviewLoading = false;
      this.markdownPreview = data.body || __('Nothing to preview.');

      this.$nextTick()
        .then(() => {
          renderGFM(this.$refs['markdown-preview']);
        })
        .catch(() =>
          createAlert({
            message: __('Error rendering Markdown preview'),
          }),
        );
    },
  },
  safeHtmlConfig: {
    ADD_TAGS: ['gl-emoji'],
  },
};
</script>

<template>
  <div
    ref="gl-form"
    :class="{ 'gl-mt-3 gl-mb-3': addSpacingClasses }"
    class="js-vue-markdown-field md-area position-relative gfm-form"
    :data-uploads-path="uploadsPath"
  >
    <markdown-header
      :preview-markdown="previewMarkdown"
      :line-content="lineContent"
      :can-suggest="canSuggest"
      :enable-preview="enablePreview"
      :show-suggest-popover="showSuggestPopover"
      :suggestion-start-index="suggestionsStartIndex"
      :uploads-path="uploadsPath"
      :markdown-preview-path="markdownPreviewPath"
      :drawio-enabled="drawioEnabled"
      data-testid="markdownHeader"
      :restricted-tool-bar-items="restrictedToolBarItems"
      :show-content-editor-switcher="showContentEditorSwitcher"
      @showPreview="showPreview"
      @hidePreview="hidePreview"
      @handleSuggestDismissed="() => $emit('handleSuggestDismissed')"
      @enableContentEditor="$emit('enableContentEditor')"
    />
    <div v-show="!previewMarkdown" class="md-write-holder">
      <div class="zen-backdrop">
        <slot name="textarea"></slot>
        <a
          class="zen-control zen-control-leave js-zen-leave gl-text-gray-500"
          href="#"
          :aria-label="__('Leave zen mode')"
        >
          <gl-icon :size="16" name="minimize" />
        </a>
        <markdown-toolbar
          :markdown-docs-path="markdownDocsPath"
          :quick-actions-docs-path="quickActionsDocsPath"
          :can-attach-file="canAttachFile"
          :show-comment-tool-bar="showCommentToolBar"
        />
      </div>
    </div>
    <template v-if="hasSuggestion">
      <div
        v-show="previewMarkdown"
        ref="markdown-preview"
        class="js-vue-md-preview md-preview-holder gl-px-5"
      >
        <suggestions
          v-if="hasSuggestion"
          :note-html="markdownPreview"
          :line-type="lineType"
          :disabled="true"
          :suggestions="suggestions"
          :help-page-path="helpPagePath"
        />
      </div>
    </template>
    <template v-else>
      <div
        v-show="previewMarkdown"
        ref="markdown-preview"
        v-safe-html:[$options.safeHtmlConfig]="markdownPreview"
        class="js-vue-md-preview md md-preview-holder gl-px-5"
      ></div>
    </template>
    <div
      v-if="referencedCommands && previewMarkdown && !markdownPreviewLoading"
      v-safe-html:[$options.safeHtmlConfig]="referencedCommands"
      class="referenced-commands gl-mx-2 gl-mb-2 gl-px-4 gl-rounded-bottom-left-base gl-rounded-bottom-right-base"
      data-testid="referenced-commands"
    ></div>
    <div v-if="shouldShowReferencedUsers" class="referenced-users">
      <gl-icon name="warning-solid" />
      <span v-safe-html:[$options.safeHtmlConfig]="addMultipleToDiscussionWarning"></span>
    </div>
  </div>
</template>
