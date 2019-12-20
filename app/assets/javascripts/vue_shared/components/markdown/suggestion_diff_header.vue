<script>
import { GlButton, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: { Icon, GlButton, GlLoadingIcon },
  directives: { 'gl-tooltip': GlTooltipDirective },
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
    <div class="qa-suggestion-diff-header js-suggestion-diff-header font-weight-bold">
      {{ __('Suggested change') }}
      <a v-if="helpPagePath" :href="helpPagePath" :aria-label="__('Help')" class="js-help-btn">
        <icon name="question-o" css-classes="link-highlight" />
      </a>
    </div>
    <span v-if="isApplied" class="badge badge-success">{{ __('Applied') }}</span>
    <div v-if="isApplying" class="d-flex align-items-center text-secondary">
      <gl-loading-icon class="d-flex-center mr-2" />
      <span>{{ __('Applying suggestion') }}</span>
    </div>
    <gl-button
      v-else-if="canApply"
      v-gl-tooltip.viewport="__('This also resolves the discussion')"
      class="btn-inverted js-apply-btn"
      :disabled="isApplying"
      variant="success"
      @click="applySuggestion"
    >
      {{ __('Apply suggestion') }}
    </gl-button>
  </div>
</template>
