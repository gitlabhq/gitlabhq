<script>
import { GlTooltipDirective, GlLink, GlIcon } from '@gitlab/ui';
import { n__ } from '~/locale';

export default {
  name: 'ReleaseBlockMilestones',
  components: {
    GlLink,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    milestones: {
      type: Array,
      required: true,
    },
  },
  computed: {
    labelText() {
      return n__('Milestone', 'Milestones', this.milestones.length);
    },
  },
};
</script>

<template>
  <div>
    <div class="js-milestone-list-label">
      <gl-icon name="flag" class="align-middle" />
      <span class="js-label-text">{{ labelText }}</span>
    </div>

    <template v-for="(milestone, index) in milestones">
      <gl-link
        :key="milestone.id"
        v-gl-tooltip
        :title="milestone.description"
        :href="milestone.webUrl"
        class="mx-1 js-milestone-link"
      >
        {{ milestone.title }}
      </gl-link>
      <template v-if="index !== milestones.length - 1">
        &bull;
      </template>
    </template>
  </div>
</template>
