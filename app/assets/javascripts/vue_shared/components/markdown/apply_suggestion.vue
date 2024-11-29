<script>
import { GlDisclosureDropdown, GlForm, GlFormTextarea, GlButton, GlAlert } from '@gitlab/ui';
import { __, n__ } from '~/locale';

export default {
  components: { GlDisclosureDropdown, GlForm, GlFormTextarea, GlButton, GlAlert },
  props: {
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    defaultCommitMessage: {
      type: String,
      required: false,
      default: null,
    },
    batchSuggestionsCount: {
      type: Number,
      required: false,
      default: 0,
    },
    errorMessage: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      message: null,
    };
  },
  computed: {
    dropdownText() {
      if (this.batchSuggestionsCount <= 1) {
        return __('Apply suggestion');
      }

      return n__('Apply %d suggestion', 'Apply %d suggestions', this.batchSuggestionsCount);
    },
    helperText() {
      if (this.batchSuggestionsCount <= 1) {
        return __('This also resolves this thread');
      }

      return __('This also resolves all related threads');
    },
  },
  methods: {
    onApply() {
      this.$emit('apply', this.message);
    },
    focusCommitMessageInput() {
      this.$refs.commitMessage.$el.focus();
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    data-testid="apply-suggestion-dropdown"
    fluid-width
    placement="bottom-end"
    size="small"
    :disabled="disabled"
    :toggle-text="dropdownText"
    @shown="focusCommitMessageInput"
  >
    <gl-form class="!gl-mx-0 !gl-my-2 gl-flex gl-flex-col !gl-px-4">
      <label for="commit-message">{{ __('Commit message') }}</label>
      <gl-alert v-if="errorMessage" variant="danger" :dismissible="false" class="gl-mb-4">
        {{ errorMessage }}
      </gl-alert>

      <gl-form-textarea
        id="commit-message"
        ref="commitMessage"
        v-model="message"
        class="apply-suggestions-input-min-width"
        :placeholder="defaultCommitMessage"
        submit-on-enter
        data-testid="commit-message-field"
        no-resize
        @submit="onApply"
      />

      <span class="gl-mt-2 gl-text-subtle">
        {{ helperText }}
      </span>

      <gl-button
        class="gl-mt-3 !gl-w-auto gl-self-end"
        category="primary"
        variant="confirm"
        data-testid="commit-with-custom-message-button"
        @click="onApply"
      >
        {{ __('Apply') }}
      </gl-button>
    </gl-form>
  </gl-disclosure-dropdown>
</template>
