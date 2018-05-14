<script>
import timeAgoTooltip from '../../vue_shared/components/time_ago_tooltip.vue';

export default {
  name: 'EditedNoteText',
  components: {
    timeAgoTooltip,
  },
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
      required: false,
      default: () => ({}),
    },
    className: {
      type: String,
      required: false,
      default: 'edited-text',
    },
  },
};
</script>

<template>
  <div :class="className">
    {{ actionText }}
    <time-ago-tooltip
      :time="editedAt"
      tooltip-placement="bottom"
    />
    <template v-if="editedBy">
      by
      <a
        :href="editedBy.path"
        class="js-vue-author author_link">
        {{ editedBy.name }}
      </a>
    </template>
  </div>
</template>
