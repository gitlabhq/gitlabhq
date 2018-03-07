<script>
  import icon from '../../../vue_shared/components/icon.vue';
  import tooltip from '../../../vue_shared/directives/tooltip';

  /**
   * Renders either a cancel, retry or play icon pointing to the given path.
   * TODO: Remove UJS from here and use an async request instead.
   */
  export default {
    components: {
      icon,
    },

    directives: {
      tooltip,
    },
    props: {
      tooltipText: {
        type: String,
        required: true,
      },

      link: {
        type: String,
        required: true,
      },

      actionMethod: {
        type: String,
        required: true,
      },

      actionIcon: {
        type: String,
        required: true,
      },
    },
  };
</script>
<template>
  <a
    v-tooltip
    :data-method="actionMethod"
    :title="tooltipText"
    :href="link"
    rel="nofollow"
    class="ci-action-icon-wrapper js-ci-status-icon"
    data-container="body"
    aria-label="Job's action"
  >
    <icon :name="actionIcon" />
  </a>
</template>
