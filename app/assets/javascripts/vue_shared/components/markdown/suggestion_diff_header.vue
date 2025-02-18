<script>
import { GlBadge, GlButton, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import ApplySuggestion from './apply_suggestion.vue';

const APPLY_SUGGESTION_ERROR_MESSAGE = __(
  'Unable to fully load the default commit message. You can still apply this suggestion and the commit message will be correct.',
);

export default {
  components: { GlBadge, GlButton, GlLoadingIcon, ApplySuggestion, HelpIcon },
  directives: { GlTooltip: GlTooltipDirective },
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
    defaultCommitMessage: {
      type: String,
      required: false,
      default: null,
    },
    inapplicableReason: {
      type: String,
      required: false,
      default: null,
    },
    suggestionsCount: {
      type: Number,
      required: false,
      default: 0,
    },
    failedToLoadMetadata: {
      type: Boolean,
      required: false,
      default: false,
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
      if (!this.canApply) {
        return this.inapplicableReason;
      }

      return false;
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
    isLoggedIn() {
      return isLoggedIn();
    },
    showApplySuggestion() {
      if (!this.isLoggedIn) return false;

      if (this.batchSuggestionsCount >= 1 && !this.isBatched) {
        return false;
      }

      return true;
    },
    applySuggestionErrorMessage() {
      return this.failedToLoadMetadata ? APPLY_SUGGESTION_ERROR_MESSAGE : null;
    },
  },
  methods: {
    apply(message) {
      if (this.batchSuggestionsCount > 1) {
        this.applySuggestionBatch(message);
      } else {
        this.applySuggestion(message);
      }
    },
    applySuggestion(message) {
      if (!this.canApply) return;
      this.isApplyingSingle = true;

      this.$emit('apply', this.applySuggestionCallback, message);
    },
    applySuggestionCallback() {
      this.isApplyingSingle = false;
    },
    applySuggestionBatch(message) {
      if (!this.canApply) return;
      this.$emit('applyBatch', message);
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
  <div
    class="md-suggestion-header border-bottom-0 gl-flex-col gl-items-start gl-gap-3 gl-px-4 gl-py-3 sm:gl-flex-row sm:gl-flex-wrap"
  >
    <div class="js-suggestion-diff-header gl-font-bold">
      {{ __('Suggested change') }}
      <a v-if="helpPagePath" :href="helpPagePath" :aria-label="__('Help')" class="js-help-btn">
        <help-icon />
      </a>
    </div>
    <gl-badge v-if="isApplied" variant="success" data-testid="applied-badge">
      {{ __('Applied') }}
    </gl-badge>
    <div
      v-else-if="isApplying"
      class="gl-flex gl-items-center gl-text-subtle"
      data-testid="applying-badge"
    >
      <gl-loading-icon size="sm" class="gl-mr-3 gl-items-center gl-justify-center" />
      <span>{{ applyingSuggestionsMessage }}</span>
    </div>
    <div v-else-if="isLoggedIn" class="gl-flex gl-flex-wrap gl-items-center gl-gap-3">
      <div v-if="isBatched">
        <gl-button
          class="js-remove-from-batch-btn"
          :disabled="isApplying"
          size="small"
          @click="removeSuggestionFromBatch"
        >
          {{ __('Remove from batch') }}
        </gl-button>
      </div>
      <div v-else-if="!isDisableButton && suggestionsCount > 1">
        <gl-button
          class="js-add-to-batch-btn"
          data-testid="add-suggestion-batch-button"
          :disabled="isDisableButton"
          size="small"
          @click="addSuggestionToBatch"
        >
          {{ __('Add suggestion to batch') }}
        </gl-button>
      </div>
      <apply-suggestion
        v-if="showApplySuggestion"
        v-gl-tooltip.viewport="tooltipMessage"
        :disabled="isDisableButton"
        :default-commit-message="defaultCommitMessage"
        :batch-suggestions-count="batchSuggestionsCount"
        :error-message="applySuggestionErrorMessage"
        @apply="apply"
      />
    </div>
  </div>
</template>
