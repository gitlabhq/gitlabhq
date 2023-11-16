<script>
import { GlIcon, GlPopover } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import { MAX_TITLE_LENGTH, MAX_BODY_LENGTH } from '../../constants';

export default {
  components: {
    GlIcon,
    GlPopover,
  },
  props: {
    text: {
      type: String,
      required: true,
    },
    placeholder: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      scrollTop: 0,
      isFocused: false,
    };
  },
  computed: {
    allLines() {
      return this.text.split('\n').map((line, i) => ({
        text: line.substr(0, this.getLineLength(i)) || ' ',
        highlightedText: line.substr(this.getLineLength(i)),
      }));
    },
  },
  methods: {
    handleScroll() {
      if (this.$refs.textarea) {
        this.$nextTick(() => {
          this.scrollTop = this.$refs.textarea.scrollTop;
        });
      }
    },
    getLineLength(i) {
      return i === 0 ? MAX_TITLE_LENGTH : MAX_BODY_LENGTH;
    },
    onInput(e) {
      this.$emit('input', e.target.value);
    },
    onCtrlEnter() {
      if (!this.isFocused) return;
      this.$emit('submit');
    },
    updateIsFocused(isFocused) {
      this.isFocused = isFocused;
    },
  },
  popoverOptions: {
    triggers: 'hover',
    placement: 'top',
    content: sprintf(
      __(`
        The character highlighter helps you keep the subject line to %{titleLength} characters
        and wrap the body at %{bodyLength} so they are readable in git.
      `),
      { titleLength: MAX_TITLE_LENGTH, bodyLength: MAX_BODY_LENGTH },
    ),
  },
};
</script>

<template>
  <fieldset
    class="gl-rounded-base gl-inset-border-1-gray-400 gl-py-4 gl-px-5"
    :class="{
      'gl-outline-none! gl-focus-ring-border-1-gray-900!': isFocused,
    }"
  >
    <div
      v-once
      class="gl-display-flex gl-align-items-center gl-border-b-solid gl-border-b-1 gl-border-b-gray-100 gl-pb-3 gl-mb-3"
    >
      <div>{{ __('Commit Message') }}</div>
      <div id="commit-message-popover-container">
        <span id="commit-message-question" class="gl-gray-700 gl-ml-3">
          <gl-icon name="question-o" />
        </span>
        <gl-popover
          target="commit-message-question"
          container="commit-message-popover-container"
          v-bind="$options.popoverOptions"
        />
      </div>
    </div>
    <div class="gl-relative gl-w-full gl-h-13 gl-overflow-hidden">
      <div class="gl-absolute gl-z-index-1 gl-font-monospace gl-text-transparent">
        <div
          data-testid="highlights"
          :style="{
            transform: `translate3d(0, ${-scrollTop}px, 0)`,
          }"
        >
          <div v-for="(line, index) in allLines" :key="index">
            <span
              data-testid="highlights-text"
              class="gl-white-space-pre-wrap gl-word-break-word"
              v-text="line.text"
            >
            </span
            ><mark
              v-show="line.highlightedText"
              data-testid="highlights-mark"
              class="gl-px-1 gl-py-0 gl-bg-orange-100 gl-text-transparent gl-white-space-pre-wrap gl-word-break-word"
              v-text="line.highlightedText"
            >
            </mark>
          </div>
        </div>
      </div>
      <textarea
        ref="textarea"
        :placeholder="placeholder"
        :value="text"
        class="gl-absolute gl-w-full gl-h-full gl-z-index-2 gl-font-monospace p-0 gl-outline-0 gl-bg-transparent gl-border-0"
        dir="auto"
        name="commit-message"
        @scroll="handleScroll"
        @input="onInput"
        @focus="updateIsFocused(true)"
        @blur="updateIsFocused(false)"
        @keydown.ctrl.enter="onCtrlEnter"
        @keydown.meta.enter="onCtrlEnter"
      >
      </textarea>
    </div>
  </fieldset>
</template>
