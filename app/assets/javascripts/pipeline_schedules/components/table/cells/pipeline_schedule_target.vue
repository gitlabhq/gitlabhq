<script>
import { GlIcon, GlLink } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
    GlLink,
  },
  props: {
    schedule: {
      type: Object,
      required: true,
    },
  },
  computed: {
    iconName() {
      return this.schedule.forTag ? 'tag' : 'fork';
    },
    refPath() {
      return this.schedule.refPath;
    },
    refDisplay() {
      return this.schedule.refForDisplay;
    },
  },
};
</script>

<template>
  <div>
    <gl-icon :name="iconName" />
    <span v-if="refPath">
      <gl-link :href="refPath" class="gl-text-gray-900">{{ refDisplay }}</gl-link>
    </span>
  </div>
</template>
