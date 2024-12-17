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
  <div data-testid="pipeline-schedule-target">
    <span v-if="refPath">
      <gl-icon :name="iconName" />
      <gl-link :href="refPath" class="gl-text-default">{{ refDisplay }}</gl-link>
    </span>
    <span v-else>
      {{ s__('PipelineSchedules|None') }}
    </span>
  </div>
</template>
