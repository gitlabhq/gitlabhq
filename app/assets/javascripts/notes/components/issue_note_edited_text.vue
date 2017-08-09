<script>
  import timeAgoTooltip from '../../vue_shared/components/time_ago_tooltip.vue';

  export default {
    name: 'editedNoteText',
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
    {{actionText}}
    <time-ago-tooltip
      :time="editedAt"
      tooltip-placement="bottom"
      />
    by
    <a
      :href="editedBy.path"
      class="js-vue-author author_link">
      {{editedBy.name}}
    </a>
  </div>
</template>
