<script>
import { __, sprintf } from '../../../locale';
import Icon from '../../../vue_shared/components/icon.vue';
import popover from '../../../vue_shared/directives/popover';
import { MAX_TITLE_LENGTH, MAX_BODY_LENGTH } from '../../constants';

export default {
  directives: {
    popover,
  },
  components: {
    Icon,
  },
  props: {
    text: {
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
      return this.text.replace(/\n$/g, '\n\n').split('\n');
    },
  },
  methods: {
    handleScroll() {
      this.$nextTick(() => {
        if (this.$refs.textarea) {
          this.scrollTop = this.$refs.textarea.scrollTop;
        }
      });
    },
    getLineLength(i) {
      return i === 0 ? MAX_TITLE_LENGTH : MAX_BODY_LENGTH;
    },
    onInput(e) {
      this.$emit('input', e.target.value);
    },
    updateIsFocused(isFocused) {
      this.isFocused = isFocused;
    },
  },
  popoverOptions: {
    trigger: 'hover',
    placement: 'top',
    content: sprintf(
      __(`
        The character highligher helps you keep the subject line to %{titleLength} characters
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
      class="md-area"
      :class="{
        'is-focused': isFocused
      }"
    >
      <div
        v-once
        class="md-header"
      >
        <ul class="nav-links">
          <li>
            {{ __('Commit Message') }}
            <span
              v-popover="$options.popoverOptions"
              class="help-block prepend-left-10"
            >
              <icon
                name="question"
              />
            </span>
          </li>
        </ul>
      </div>
      <div class="ide-commit-message-textarea-container">
        <div class="ide-commit-message-highlights-container">
          <div
            class="note-textarea highlights monospace"
            :style="{
              transform: `translate3d(0, ${-scrollTop}px, 0)`
            }"
          >
            <div
              v-for="(line, index) in allLines"
              :key="index"
            >
              <span
                v-text="line.substr(0, getLineLength(index)) || ' '"
              >
              </span><mark
                v-show="line.length > getLineLength(index)"
                v-text="line.substr(getLineLength(index))"
              >
              </mark>
            </div>
          </div>
        </div>
        <textarea
          class="note-textarea ide-commit-message-textarea"
          name="commit-message"
          :placeholder="__('Write a commit message...')"
          :value="text"
          @scroll="handleScroll"
          @input="onInput"
          @focus="updateIsFocused(true)"
          @blur="updateIsFocused(false)"
          ref="textarea"
        >
        </textarea>
      </div>
    </div>
  </fieldset>
</template>
