<script>
import { GlDeprecatedButton, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import { __ } from '~/locale';

export default {
  components: { Icon, GlDeprecatedButton, GlLoadingIcon },
  directives: { 'gl-tooltip': GlTooltipDirective },
  props: {
    batchSuggestionsCount: {
      type: Number,
      required: false,
      default: 0,
    },
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
    isBatched: {
      type: Boolean,
      required: false,
      default: false,
    },
    isApplyingBatch: {
      type: Boolean,
      required: false,
      default: false,
    },
    helpPagePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isApplyingSingle: false,
    };
  },
  computed: {
    isApplying() {
      return this.isApplyingSingle || this.isApplyingBatch;
    },
    tooltipMessage() {
      return this.canApply
        ? __('This also resolves the discussion')
        : __("Can't apply as this line has changed or the suggestion already matches its content.");
    },
    isDisableButton() {
      return this.isApplying || !this.canApply;
    },
    applyingSuggestionsMessage() {
      if (this.isApplyingSingle || this.batchSuggestionsCount < 2) {
        return __('Applying suggestion...');
      }
      return __('Applying suggestions...');
    },
  },
  methods: {
    applySuggestion() {
      if (!this.canApply) return;
      this.isApplyingSingle = true;
      this.$emit('apply', this.applySuggestionCallback);
    },
    applySuggestionCallback() {
      this.isApplyingSingle = false;
    },
    applySuggestionBatch() {
      if (!this.canApply) return;
      this.$emit('applyBatch');
    },
    addSuggestionToBatch() {
      this.$emit('addToBatch');
    },
    removeSuggestionFromBatch() {
      this.$emit('removeFromBatch');
    },
  },
};
</script>

<template>
  <div class="md-suggestion-header border-bottom-0 mt-2">
    <div class="qa-suggestion-diff-header js-suggestion-diff-header font-weight-bold">
      {{ __('Suggested change') }}
      <a v-if="helpPagePath" :href="helpPagePath" :aria-label="__('Help')" class="js-help-btn">
        <icon name="question-o" css-classes="link-highlight" />
      </a>
    </div>
    <div v-if="isApplied" class="badge badge-success">{{ __('Applied') }}</div>
    <div v-else-if="isApplying" class="d-flex align-items-center text-secondary">
      <gl-loading-icon class="d-flex-center mr-2" />
      <span>{{ applyingSuggestionsMessage }}</span>
    </div>
    <div v-else-if="canApply && isBatched" class="d-flex align-items-center">
      <gl-deprecated-button
        class="btn-inverted js-remove-from-batch-btn btn-grouped"
        :disabled="isApplying"
        @click="removeSuggestionFromBatch"
      >
        {{ __('Remove from batch') }}
      </gl-deprecated-button>
      <gl-deprecated-button
        v-gl-tooltip.viewport="__('This also resolves all related threads')"
        class="btn-inverted js-apply-batch-btn btn-grouped"
        :disabled="isApplying"
        variant="success"
        @click="applySuggestionBatch"
      >
        {{ __('Apply suggestions') }}
        <span class="badge badge-pill badge-pill-success">
          {{ batchSuggestionsCount }}
        </span>
      </gl-deprecated-button>
    </div>
    <div v-else class="d-flex align-items-center">
      <gl-deprecated-button
        class="btn-inverted js-add-to-batch-btn btn-grouped"
        :disabled="isDisableButton"
        @click="addSuggestionToBatch"
      >
        {{ __('Add suggestion to batch') }}
      </gl-deprecated-button>
      <span v-gl-tooltip.viewport="tooltipMessage" tabindex="0">
        <gl-deprecated-button
          class="btn-inverted js-apply-btn btn-grouped"
          :disabled="isDisableButton"
          variant="success"
          @click="applySuggestion"
        >
          {{ __('Apply suggestion') }}
        </gl-deprecated-button>
      </span>
    </div>
  </div>
</template>
