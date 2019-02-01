<script>
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: { Icon },
  props: {
    canApply: {
      type: Boolean,
      required: false,
      default: false,
    },
    isApplied: {
      type: Boolean,
      required: true,
      default: false,
    },
    helpPagePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isAppliedSuccessfully: false,
      isApplying: false,
    };
  },
  methods: {
    applySuggestion() {
      if (!this.canApply) return;
      this.isApplying = true;
      this.$emit('apply', this.applySuggestionCallback);
    },
    applySuggestionCallback() {
      this.isApplying = false;
    },
  },
};
</script>

<template>
  <div class="md-suggestion-header border-bottom-0 mt-2">
    <div class="qa-suggestion-diff-header font-weight-bold">
      {{ __('Suggested change') }}
      <a v-if="helpPagePath" :href="helpPagePath" :aria-label="__('Help')" class="js-help-btn">
        <icon name="question-o" css-classes="link-highlight" />
      </a>
    </div>
    <span v-if="isApplied" class="badge badge-success">{{ __('Applied') }}</span>
    <button
      v-if="canApply"
      type="button"
      class="btn qa-apply-btn"
      :disabled="isApplying"
      @click="applySuggestion"
    >
      {{ __('Apply suggestion') }}
    </button>
  </div>
</template>
