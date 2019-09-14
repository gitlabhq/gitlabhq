<script>
import { GlLink, GlTooltipDirective } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import { s__ } from '~/locale';

export default {
  name: 'MilestoneList',
  components: {
    GlLink,
    Icon,
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
      return this.milestones.length === 1 ? s__('Milestone') : s__('Milestones');
    },
  },
};
</script>
<template>
  <div>
    <icon name="flag" class="align-middle" /> <span class="js-label-text">{{ labelText }}</span>
    <template v-for="(milestone, index) in milestones">
      <gl-link
        :key="milestone.id"
        v-gl-tooltip
        :title="milestone.description"
        :href="milestone.web_url"
      >
        {{ milestone.title }}
      </gl-link>
      <template v-if="index !== milestones.length - 1">
        &bull;
      </template>
    </template>
  </div>
</template>
