<script>
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import relatedIssuableMixin from '~/issuable/mixins/related_issuable_mixin';

export default {
  name: 'IssueToken',
  components: {
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [relatedIssuableMixin],
  props: {
    isCondensed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    removeButtonLabel() {
      const { displayReference } = this;
      /*
       * Giving false as third argument to prevent unescaping of ampersand in
       * epic reference. Eg. &42 will remain &42 instead of &amp;42
       *
       * https://docs.gitlab.com/ee/development/i18n/externalization.html#interpolation
       */
      return sprintf(__('Remove %{displayReference}'), { displayReference }, false);
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
      'issue-token gl-inline-flex gl-max-w-full gl-items-stretch gl-whitespace-nowrap gl-leading-24':
        isCondensed,
      'issuable-info-container flex-row': !isCondensed,
    }"
  >
    <component
      :is="computedLinkElementType"
      ref="link"
      v-gl-tooltip
      :class="{
        'issue-token-link gl-inline-flex gl-min-w-0 gl-text-gray-500': isCondensed,
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
          'issue-token-title issue-token-end gl-flex gl-items-baseline gl-overflow-hidden gl-pl-3 gl-text-gray-500':
            isCondensed,
          'issue-title block-truncated': !isCondensed,
          'gl-rounded-br-small gl-rounded-tr-small gl-pr-3': !canRemove,
        }"
        class="js-issue-token-title"
      >
        <span class="gl-truncate">{{ title }}</span>
      </component>
      <component
        :is="innerComponentType"
        ref="reference"
        :class="{
          'issue-token-reference gl-flex gl-items-center gl-rounded-bl-small gl-rounded-tl-small gl-px-3':
            isCondensed,
          'issuable-info': !isCondensed,
        }"
      >
        <gl-icon
          v-if="hasState"
          v-gl-tooltip
          :class="iconClass"
          :name="iconName"
          :size="12"
          :title="stateTitle"
          :aria-label="state"
          data-testid="referenceIcon"
        />
        {{ displayReference }}
      </component>
    </component>
    <button
      v-if="canRemove"
      ref="removeButton"
      v-gl-tooltip
      :class="{
        'issue-token-remove-button gl-flex gl-items-center gl-rounded-br-small gl-rounded-tr-small gl-border-0 gl-px-3 gl-text-gray-500':
          isCondensed,
        'btn btn-default quarantined-deprecated-btn': !isCondensed,
      }"
      :title="removeButtonLabel"
      :aria-label="removeButtonLabel"
      :disabled="removeDisabled"
      data-testid="removeBtn"
      type="button"
      @click="onRemoveRequest"
    >
      <gl-icon name="close" />
    </button>
  </div>
</template>
