<script>
import $ from 'jquery';
import { GlPopover, GlButton, GlTooltipDirective } from '@gitlab/ui';
import ToolbarButton from './toolbar_button.vue';
import Icon from '../icon.vue';

export default {
  components: {
    ToolbarButton,
    Icon,
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
  },
  computed: {
    mdTable() {
      return [
        // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/26
        '| header | header |', // eslint-disable-line @gitlab/i18n/no-non-i18n-strings
        '| ------ | ------ |',
        '| cell | cell |', // eslint-disable-line @gitlab/i18n/no-non-i18n-strings
        '| cell | cell |', // eslint-disable-line @gitlab/i18n/no-non-i18n-strings
      ].join('\n');
    },
    mdSuggestion() {
      return ['```suggestion:-0+0', `{text}`, '```'].join('\n');
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
  },
};
</script>

<template>
  <div class="md-header">
    <ul class="nav-links clearfix">
      <li :class="{ active: !previewMarkdown }" class="md-header-tab">
        <button class="js-write-link" tabindex="-1" type="button" @click="writeMarkdownTab($event)">
          {{ __('Write') }}
        </button>
      </li>
      <li :class="{ active: previewMarkdown }" class="md-header-tab">
        <button
          class="js-preview-link js-md-preview-button"
          tabindex="-1"
          type="button"
          @click="previewMarkdownTab($event)"
        >
          {{ __('Preview') }}
        </button>
      </li>
      <li :class="{ active: !previewMarkdown }" class="md-header-toolbar">
        <div class="d-inline-block">
          <toolbar-button tag="**" :button-title="__('Add bold text')" icon="bold" />
          <toolbar-button tag="*" :button-title="__('Add italic text')" icon="italic" />
          <toolbar-button
            :prepend="true"
            tag="> "
            :button-title="__('Insert a quote')"
            icon="quote"
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
              class="js-suggestion-btn"
              @click="handleSuggestDismissed"
            />
            <gl-popover
              v-if="showSuggestPopover"
              :target="() => $refs.suggestButton"
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
              <gl-button variant="primary" size="sm" @click="handleSuggestDismissed">
                {{ __('Got it') }}
              </gl-button>
            </gl-popover>
          </template>
          <toolbar-button tag="`" tag-block="```" :button-title="__('Insert code')" icon="code" />
          <toolbar-button
            tag="[{text}](url)"
            tag-select="url"
            :button-title="__('Add a link')"
            icon="link"
          />
        </div>
        <div class="d-inline-block ml-md-2 ml-0">
          <toolbar-button
            :prepend="true"
            tag="* "
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
            tag="* [ ] "
            :button-title="__('Add a task list')"
            icon="list-task"
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
            <icon name="screen-full" />
          </button>
        </div>
      </li>
    </ul>
  </div>
</template>
