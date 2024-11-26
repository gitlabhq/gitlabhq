<script>
import { GlIcon, GlTooltip, GlLink } from '@gitlab/ui';

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
};
</script>

<template>
  <div
    ref="branchInfo"
    class="gl-grid-cols-[auto, 1fr] gl-grid gl-w-fit gl-gap-2 gl-gap-5 gl-p-2 gl-pl-0 gl-pr-3"
  >
    <gl-link
      :href="itemContent.comparePath"
      class="gl-truncate gl-text-primary hover:gl-text-primary hover:gl-underline"
    >
      <gl-icon name="branch" class="gl-text-gray-500" />
      {{ itemContent.name }}
    </gl-link>
    <gl-tooltip :target="() => $refs.branchInfo" placement="top">
      <div class="gl-font-bold">{{ __('Branch') }}</div>
      <div>{{ itemContent.name }}</div>
    </gl-tooltip>
  </div>
</template>
