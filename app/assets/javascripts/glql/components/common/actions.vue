<script>
import { GlDisclosureDropdown, GlTooltipDirective } from '@gitlab/ui';
import { identity, uniqueId } from 'lodash';
import { __ } from '~/locale';
import { eventHubByKey } from '../../utils/event_hub_factory';

export default {
  name: 'GlqlActions',
  components: {
    GlDisclosureDropdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['queryKey'],
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
      eventHub: eventHubByKey(this.queryKey),
      toggleId: uniqueId('dropdown-toggle-btn-'),
    };
  },
  computed: {
    items() {
      return [
        {
          text: __('View source'),
          action: () =>
            this.eventHub.$emit('dropdownAction', 'viewSource', { title: this.modalTitle }),
        },
        {
          text: __('Copy source'),
          action: () => this.eventHub.$emit('dropdownAction', 'copySource'),
        },
        this.showCopyContents && {
          text: __('Copy contents'),
          action: () => this.eventHub.$emit('dropdownAction', 'copyAsGFM'),
        },
      ].filter(identity);
    },
  },
};
</script>
<template>
  <div class="gl-inline-flex gl-self-start gl-align-middle">
    <gl-disclosure-dropdown
      v-gl-tooltip
      class="glql-actions"
      :title="__('GLQL view options')"
      :items="items"
      :toggle-id="toggleId"
      :no-caret="true"
      size="small"
      category="tertiary"
      icon="ellipsis_v"
      :toggle-text="__('GLQL view options')"
      text-sr-only
      placement="bottom-end"
      positioning-strategy="fixed"
    />
  </div>
</template>
