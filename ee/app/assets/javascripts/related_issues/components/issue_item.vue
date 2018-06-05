<script>
import { __ } from '~/locale';
import relatedIssueMixin from '../mixins/related_issues_mixin';

export default {
  name: 'IssueItem',
  mixins: [relatedIssueMixin],
  props: {
    canReorder: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    stateTitle() {
      return this.isOpen ? __('Open') : __('Closed');
    },
  },
};
</script>

<template>
  <div
    class="flex"
    :class="{
      'issue-info-container': !canReorder,
      'card-body': canReorder,
    }"
  >
    <div class="block-truncated append-right-10">
      <a
        class="issue-token-title-text sortable-link"
        :href="computedPath"
      >
        {{ title }}
      </a>
      <div class="block text-secondary">
        <icon
          v-if="hasState"
          v-tooltip
          :css-classes="iconClass"
          :name="iconName"
          :size="12"
          :title="stateTitle"
          :aria-label="state"
        />
        {{ displayReference }}
      </div>
    </div>
    <button
      v-if="canRemove"
      v-tooltip
      ref="removeButton"
      type="button"
      class="btn btn-default js-issue-item-remove-button flex-align-self-center flex-right"
      title="Remove"
      aria-label="Remove"
      :disabled="removeDisabled"
      @click="onRemoveRequest"
    >
      <i
        class="fa fa-times"
        aria-hidden="true"
      >
      </i>
    </button>
  </div>
</template>
