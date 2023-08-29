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
    data-qa-selector="apply_suggestion_dropdown"
    fluid-width
    placement="right"
    size="small"
    :disabled="disabled"
    :toggle-text="dropdownText"
    @shown="focusCommitMessageInput"
  >
    <gl-form class="gl-display-flex gl-flex-direction-column gl-px-4! gl-mx-0! gl-my-2!">
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
        data-qa-selector="commit_message_field"
        @submit="onApply"
      />

      <gl-button
        class="gl-w-auto! gl-mt-3 gl-align-self-end"
        category="primary"
        variant="confirm"
        data-qa-selector="commit_with_custom_message_button"
        @click="onApply"
      >
        {{ __('Apply') }}
      </gl-button>
    </gl-form>
  </gl-disclosure-dropdown>
</template>
