<script>
import { GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlIcon,
  },
  props: {
    placeholder: {
      type: String,
      required: false,
      default: __('Search'),
    },
    tokens: {
      type: Array,
      required: false,
      default: () => [],
    },
    value: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      backspaceCount: 0,
    };
  },
  computed: {
    placeholderText() {
      return this.tokens.length ? '' : this.placeholder;
    },
  },
  watch: {
    tokens() {
      this.$refs.input.focus();
    },
  },
  methods: {
    onFocus() {
      this.$emit('focus');
    },
    onBlur() {
      this.$emit('blur');
    },
    onInput(evt) {
      this.$emit('input', evt.target.value);
    },
    onBackspace() {
      if (!this.value && this.tokens.length) {
        this.backspaceCount += 1;
      } else {
        this.backspaceCount = 0;
        return;
      }

      if (this.backspaceCount > 1) {
        this.removeToken(this.tokens[this.tokens.length - 1]);
        this.backspaceCount = 0;
      }
    },
    removeToken(token) {
      this.$emit('removeToken', token);
    },
  },
};
</script>

<template>
  <div class="filtered-search-wrapper">
    <div class="filtered-search-box">
      <div class="tokens-container list-unstyled">
        <div v-for="token in tokens" :key="token.label" class="filtered-search-token">
          <button
            class="selectable btn-blank"
            type="button"
            @click.stop="removeToken(token)"
            @keyup.delete="removeToken(token)"
          >
            <div class="value-container rounded">
              <div class="value">{{ token.label }}</div>
              <div class="remove-token inverted">
                <gl-icon :size="16" name="close" />
              </div>
            </div>
          </button>
        </div>
        <div class="input-token">
          <input
            ref="input"
            :placeholder="placeholderText"
            :value="value"
            type="search"
            class="form-control filtered-search"
            @input="onInput"
            @focus="onFocus"
            @blur="onBlur"
            @keyup.delete="onBackspace"
          />
        </div>
      </div>
    </div>
  </div>
</template>
