<script>
import { GlPopover, GlButton, GlTooltipDirective, GlIcon } from '@gitlab/ui';
import $ from 'jquery';
import { keysFor, BOLD_TEXT, ITALIC_TEXT, LINK_TEXT } from '~/behaviors/shortcuts/keybindings';
import { getSelectedFragment } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import { CopyAsGFM } from '../../../behaviors/markdown/copy_as_gfm';
import ToolbarButton from './toolbar_button.vue';

export default {
  components: {
    ToolbarButton,
    GlIcon,
    GlPopover,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    previewMarkdown: {
      type: Boolean,
      required: true,
    },
    lineContent: {
      type: String,
      required: false,
      default: '',
    },
    canSuggest: {
      type: Boolean,
      required: false,
      default: true,
    },
    showSuggestPopover: {
      type: Boolean,
      required: false,
      default: false,
    },
    suggestionStartIndex: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  data() {
    return {
      tag: '> ',
    };
  },
  computed: {
    mdTable() {
      return [
        // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
        '| header | header |', // eslint-disable-line @gitlab/require-i18n-strings
        '| ------ | ------ |',
        '| cell | cell |', // eslint-disable-line @gitlab/require-i18n-strings
        '| cell | cell |', // eslint-disable-line @gitlab/require-i18n-strings
      ].join('\n');
    },
    mdSuggestion() {
      return [['```', `suggestion:-${this.suggestionStartIndex}+0`].join(''), `{text}`, '```'].join(
        '\n',
      );
    },
    mdCollapsibleSection() {
      return ['<details><summary>Click to expand</summary>', `{text}`, '</details>'].join('\n');
    },
    isMac() {
      // Accessing properties using ?. to allow tests to use
      // this component without setting up window.gl.client.
      // In production, window.gl.client should always be present.
      return Boolean(window.gl?.client?.isMac);
    },
    modifierKey() {
      return this.isMac ? '⌘' : s__('KeyboardKey|Ctrl+');
    },
  },
  mounted() {
    $(document).on('markdown-preview:show.vue', this.previewMarkdownTab);
    $(document).on('markdown-preview:hide.vue', this.writeMarkdownTab);
  },
  beforeDestroy() {
    $(document).off('markdown-preview:show.vue', this.previewMarkdownTab);
    $(document).off('markdown-preview:hide.vue', this.writeMarkdownTab);
  },
  methods: {
    isValid(form) {
      return (
        !form ||
        (form.find('.js-vue-markdown-field').length && $(this.$el).closest('form')[0] === form[0])
      );
    },

    previewMarkdownTab(event, form) {
      if (event.target.blur) event.target.blur();
      if (!this.isValid(form)) return;

      this.$emit('preview-markdown');
    },

    writeMarkdownTab(event, form) {
      if (event.target.blur) event.target.blur();
      if (!this.isValid(form)) return;

      this.$emit('write-markdown');
    },
    handleSuggestDismissed() {
      this.$emit('handleSuggestDismissed');
    },
    handleQuote() {
      const documentFragment = getSelectedFragment();

      if (!documentFragment || !documentFragment.textContent) {
        this.tag = '> ';
        return;
      }
      this.tag = '';

      const transformed = CopyAsGFM.transformGFMSelection(documentFragment);
      const area = this.$el.parentNode.querySelector('textarea');

      CopyAsGFM.nodeToGFM(transformed)
        .then((gfm) => {
          CopyAsGFM.insertPastedText(area, documentFragment.textContent, CopyAsGFM.quoted(gfm));
        })
        .catch(() => {});
    },
  },
  shortcuts: {
    bold: keysFor(BOLD_TEXT),
    italic: keysFor(ITALIC_TEXT),
    link: keysFor(LINK_TEXT),
  },
};
</script>

<template>
  <div class="md-header">
    <ul class="nav-links clearfix">
      <li :class="{ active: !previewMarkdown }" class="md-header-tab">
        <button class="js-write-link" type="button" @click="writeMarkdownTab($event)">
          {{ __('Write') }}
        </button>
      </li>
      <li :class="{ active: previewMarkdown }" class="md-header-tab">
        <button
          class="js-preview-link js-md-preview-button"
          type="button"
          @click="previewMarkdownTab($event)"
        >
          {{ __('Preview') }}
        </button>
      </li>
      <li :class="{ active: !previewMarkdown }" class="md-header-toolbar">
        <div class="d-inline-block">
          <toolbar-button
            tag="**"
            :button-title="
              sprintf(s__('MarkdownEditor|Add bold text (%{modifierKey}B)'), { modifierKey })
            "
            :shortcuts="$options.shortcuts.bold"
            icon="bold"
          />
          <toolbar-button
            tag="_"
            :button-title="
              sprintf(s__('MarkdownEditor|Add italic text (%{modifierKey}I)'), { modifierKey })
            "
            :shortcuts="$options.shortcuts.italic"
            icon="italic"
          />
          <toolbar-button
            :prepend="true"
            :tag="tag"
            :button-title="__('Insert a quote')"
            icon="quote"
            @click="handleQuote"
          />
        </div>
        <div class="d-inline-block ml-md-2 ml-0">
          <template v-if="canSuggest">
            <toolbar-button
              ref="suggestButton"
              :tag="mdSuggestion"
              :prepend="true"
              :button-title="__('Insert suggestion')"
              :cursor-offset="4"
              :tag-content="lineContent"
              icon="doc-code"
              data-qa-selector="suggestion_button"
              class="js-suggestion-btn"
              @click="handleSuggestDismissed"
            />
            <gl-popover
              v-if="showSuggestPopover && $refs.suggestButton"
              :target="$refs.suggestButton"
              :css-classes="['diff-suggest-popover']"
              placement="bottom"
              :show="showSuggestPopover"
            >
              <strong>{{ __('New! Suggest changes directly') }}</strong>
              <p class="mb-2">
                {{
                  __(
                    'Suggest code changes which can be immediately applied in one click. Try it out!',
                  )
                }}
              </p>
              <gl-button
                variant="info"
                category="primary"
                size="sm"
                @click="handleSuggestDismissed"
              >
                {{ __('Got it') }}
              </gl-button>
            </gl-popover>
          </template>
          <toolbar-button tag="`" tag-block="```" :button-title="__('Insert code')" icon="code" />
          <toolbar-button
            tag="[{text}](url)"
            tag-select="url"
            :button-title="
              sprintf(s__('MarkdownEditor|Add a link (%{modifierKey}K)'), { modifierKey })
            "
            :shortcuts="$options.shortcuts.link"
            icon="link"
          />
        </div>
        <div class="d-inline-block ml-md-2 ml-0">
          <toolbar-button
            :prepend="true"
            tag="- "
            :button-title="__('Add a bullet list')"
            icon="list-bulleted"
          />
          <toolbar-button
            :prepend="true"
            tag="1. "
            :button-title="__('Add a numbered list')"
            icon="list-numbered"
          />
          <toolbar-button
            :prepend="true"
            tag="- [ ] "
            :button-title="__('Add a task list')"
            icon="list-task"
          />
          <toolbar-button
            :tag="mdCollapsibleSection"
            :prepend="true"
            tag-select="Click to expand"
            :button-title="__('Add a collapsible section')"
            icon="details-block"
          />
          <toolbar-button
            :tag="mdTable"
            :prepend="true"
            :button-title="__('Add a table')"
            icon="table"
          />
        </div>
        <div class="d-inline-block ml-md-2 ml-0">
          <button
            v-gl-tooltip
            :aria-label="__('Go full screen')"
            class="toolbar-btn toolbar-fullscreen-btn js-zen-enter"
            data-container="body"
            tabindex="-1"
            :title="__('Go full screen')"
            type="button"
          >
            <gl-icon name="maximize" />
          </button>
        </div>
      </li>
    </ul>
  </div>
</template>
