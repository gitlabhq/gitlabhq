<script>
import timeAgoTooltip from '../../vue_shared/components/time_ago_tooltip.vue';

export default {
  props: {
    actionText: {
      type: String,
      required: true,
    },
    editedAt: {
      type: String,
      required: true,
    },
    editedBy: {
      type: Object,
      required: true,
    },
    className: {
      type: String,
      required: false,
      default: 'edited-text',
    },
  },
  components: {
    timeAgoTooltip,
  },
};
</script>

<template>
  <div :class="className">
    <span>{{actionText}} </span>
    <span> by </span>
    <a
      :href="editedBy.path"
      class="author_link">
      <span>{{editedBy.name}}</span>
    </a>
    <time-ago-tooltip
      :time="editedAt"
      tooltipPlacement="bottom" />
  </div>
</template>
