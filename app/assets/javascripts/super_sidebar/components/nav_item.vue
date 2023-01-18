<script>
import { GlIcon } from '@gitlab/ui';

export default {
  name: 'NavItem',
  components: {
    GlIcon,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <li>
    <a
      :href="item.link"
      class="gl-display-flex gl-pl-3 gl-py-3 gl-line-height-normal gl-text-black-normal gl-hover-bg-t-gray-a-08"
    >
      <div class="gl-mr-3">
        <slot name="icon">
          <gl-icon v-if="item.icon" :name="item.icon" />
        </slot>
      </div>
      <div class="gl-pr-3">
        {{ item.title }}
        <div v-if="item.subtitle" class="gl-font-sm gl-text-gray-500 gl-mt-1">
          {{ item.subtitle }}
        </div>
      </div>
    </a>
  </li>
</template>
