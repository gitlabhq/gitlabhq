<script>
import { GlIcon, GlTooltip, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlIcon,
    GlTooltip,
    GlLink,
  },
  props: {
    itemContent: {
      type: Object,
      required: true,
    },
  },
  methods: {
    icon({ active }) {
      return active ? 'feature-flag' : 'feature-flag-disabled';
    },
    iconColor({ active }) {
      return active ? 'gl-text-blue-500' : 'gl-text-gray-500';
    },
    flagStatus(flag) {
      return flag.active ? __('Enabled') : __('Disabled');
    },
  },
};
</script>

<template>
  <div
    ref="flagInfo"
    class="gl-grid-cols-[auto, 1fr] gl-grid gl-w-fit gl-gap-2 gl-gap-5 gl-p-2 gl-pl-0 gl-pr-3"
  >
    <gl-link
      :href="itemContent.path"
      class="gl-truncate gl-text-primary hover:gl-text-primary hover:gl-underline"
    >
      <gl-icon :name="icon(itemContent)" :class="iconColor(itemContent)" />
      {{ itemContent.name }}
    </gl-link>
    <gl-tooltip :target="() => $refs.flagInfo" placement="top">
      <span class="gl-inline-block gl-font-bold"> {{ __('Feature flag') }} </span>
      <span class="gl-inline-block">{{ itemContent.name }} {{ itemContent.reference }}</span>
      <span class="gl-inline-block gl-text-secondary">{{ flagStatus(itemContent) }}</span>
    </gl-tooltip>
  </div>
</template>
