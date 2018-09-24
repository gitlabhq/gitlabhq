<script>
import { __ } from '~/locale';
import relatedIssueMixin from '../mixins/related_issues_mixin';

export default {
  name: 'IssueToken',
  mixins: [relatedIssueMixin],
  props: {
    isCondensed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    removeButtonLabel() {
      return `Remove ${this.displayReference}`;
    },
    stateTitle() {
      if (this.isCondensed) return '';

      return this.isOpen ? __('Open') : __('Closed');
    },
    innerComponentType() {
      return this.isCondensed ? 'span' : 'div';
    },
    issueTitle() {
      return this.isCondensed ? this.title : '';
    },
  },
};
</script>

<template>
  <div
    :class="{
      'issue-token': isCondensed,
      'flex-row issuable-info-container': !isCondensed,
    }"
  >
    <component
      :is="computedLinkElementType"
      ref="link"
      v-tooltip
      :class="{
        'issue-token-link': isCondensed,
        'issuable-main-info': !isCondensed,
      }"
      :href="computedPath"
      :title="issueTitle"
      data-placement="top"
    >
      <component
        :is="innerComponentType"
        v-if="hasTitle"
        ref="title"
        :class="{
          'issue-token-title issue-token-end': isCondensed,
          'issue-title block-truncated': !isCondensed,
          'issue-token-title-standalone': !canRemove
        }"
        class="js-issue-token-title"
      >
        <span class="issue-token-title-text">
          {{ title }}
        </span>
      </component>
      <component
        :is="innerComponentType"
        ref="reference"
        :class="{
          'issue-token-reference': isCondensed,
          'issuable-info': !isCondensed,
        }"
      >
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
      </component>
    </component>
    <button
      v-if="canRemove"
      ref="removeButton"
      v-tooltip
      :class="{
        'issue-token-remove-button': isCondensed,
        'btn btn-default': !isCondensed
      }"
      :title="removeButtonLabel"
      :aria-label="removeButtonLabel"
      :disabled="removeDisabled"
      type="button"
      class="js-issue-token-remove-button"
      @click="onRemoveRequest"
    >
      <i
        class="fa fa-times"
        aria-hidden="true">
      </i>
    </button>
  </div>
</template>
