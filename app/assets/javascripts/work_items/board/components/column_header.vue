<script>
import { GlIcon } from '@gitlab/ui';
import { getAdaptiveStatusColor } from '~/lib/utils/color_utils';

export default {
  name: 'ColumnHeader',
  components: {
    GlIcon,
  },
  props: {
    value: {
      type: Object,
      required: true,
    },
    groupProperty: {
      type: String,
      required: true,
    },
    count: {
      type: Number,
      required: true,
    },
  },
  computed: {
    showStatusIcon() {
      return this.groupProperty === 'status' && Boolean(this.value.iconName);
    },
    iconColorStyle() {
      return this.value.color ? { color: getAdaptiveStatusColor(this.value.color) } : {};
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-h-9 gl-items-center gl-gap-3 gl-px-3">
    <gl-icon name="chevron-down" :size="16" class="gl-shrink-0" />
    <gl-icon
      v-if="showStatusIcon"
      :name="value.iconName"
      :size="12"
      :style="iconColorStyle"
      class="gl-shrink-0"
    />
    <h3
      data-testid="column-header-name"
      class="gl-m-0 gl-mr-2 gl-min-w-0 gl-truncate gl-text-base gl-font-bold"
    >
      {{ value.name }}
    </h3>
    <span
      data-testid="column-header-count"
      class="gl-flex gl-shrink-0 gl-items-center gl-gap-1 gl-text-sm gl-font-bold gl-text-subtle"
    >
      <gl-icon name="work-items" :size="16" />
      {{ count }}
    </span>
    <div class="gl-ml-auto">
      <gl-icon name="ellipsis_v" :size="16" class="gl-mr-3 gl-shrink-0" />
      <gl-icon name="plus" :size="16" class="gl-shrink-0" />
    </div>
  </div>
</template>
