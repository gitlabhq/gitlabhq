<script>
import { GlPopover } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import { MAX_TITLE_LENGTH, MAX_BODY_LENGTH } from '../../constants';

export default {
  components: {
    GlPopover,
    HelpIcon,
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
  <fieldset class="common-note-form ide-commit-message-field">
    <div
      :class="{
        'is-focused': isFocused,
      }"
      class="md-area"
    >
      <div v-once class="md-header">
        <ul class="nav-links">
          <li>
            {{ __('Commit Message') }}
            <div id="ide-commit-message-popover-container">
              <span id="ide-commit-message-question" class="form-text gl-ml-3">
                <help-icon />
              </span>
              <gl-popover
                target="ide-commit-message-question"
                container="ide-commit-message-popover-container"
                v-bind="$options.popoverOptions"
              />
            </div>
          </li>
        </ul>
      </div>
      <div class="ide-commit-message-textarea-container">
        <div class="ide-commit-message-highlights-container">
          <div
            :style="{
              transform: `translate3d(0, ${-scrollTop}px, 0)`,
            }"
            class="note-textarea highlights monospace"
          >
            <div v-for="(line, index) in allLines" :key="index">
              <span v-text="line.text"> </span
              ><mark v-show="line.highlightedText" v-text="line.highlightedText"> </mark>
            </div>
          </div>
        </div>
        <textarea
          ref="textarea"
          :placeholder="placeholder"
          :value="text"
          class="note-textarea ide-commit-message-textarea"
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
    </div>
  </fieldset>
</template>
