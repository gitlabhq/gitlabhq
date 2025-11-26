<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { identity, uniqueId } from 'lodash';
import { __ } from '~/locale';

export default {
  name: 'GlqlActions',
  components: {
    GlDisclosureDropdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    modalTitle: {
      type: String,
      required: false,
      default: '',
    },
    showCopyContents: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      toggleId: uniqueId('dropdown-toggle-btn-'),
      isDropdownVisible: false,
      cachedShowCopy: this.showCopyContents,
    };
  },
  computed: {
    items() {
      return [
        {
          text: __('View source'),
          action: () => this.$emit('viewSource', { title: this.modalTitle }),
        },
        {
          text: __('Copy source'),
          action: () => this.$emit('copySource'),
        },
        this.cachedShowCopy && {
          text: __('Copy contents'),
          action: () => this.$emit('copyAsGFM'),
        },
        {
          text: __('Reload'),
          action: () => this.$emit('reload'),
        },
      ].filter(identity);
    },
    moreActionsTooltip() {
      return !this.isDropdownVisible ? __('Embedded view options') : '';
    },
  },
  methods: {
    handleDropdownShown() {
      this.cachedShowCopy = this.showCopyContents;
      this.isDropdownVisible = true;
    },
  },
};
</script>
<template>
  <div class="gl-inline-flex gl-self-start gl-align-middle">
    <gl-disclosure-dropdown
      v-gl-tooltip.top.viewport="moreActionsTooltip"
      class="glql-actions"
      :items="items"
      :toggle-id="toggleId"
      :no-caret="true"
      size="small"
      category="tertiary"
      icon="ellipsis_v"
      :toggle-text="__('Embedded view options')"
      text-sr-only
      placement="bottom-end"
      @shown="handleDropdownShown"
      @hidden="isDropdownVisible = false"
    />
  </div>
</template>
