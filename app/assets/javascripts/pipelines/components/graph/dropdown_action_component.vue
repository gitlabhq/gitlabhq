<script>
  import getActionIcon from '../../../vue_shared/ci_action_icons';
  import tooltipMixin from '../../../vue_shared/mixins/tooltip';

  /**
   * Renders either a cancel, retry or play icon pointing to the given path.
   * TODO: Remove UJS from here and use an async request instead.
   */
  export default {
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

    mixins: [
      tooltipMixin,
    ],

    computed: {
      actionIconSvg() {
        return getActionIcon(this.actionIcon);
      },
    },
  };
</script>
<template>
  <a
    :data-method="actionMethod"
    :title="tooltipText"
    :href="link"
    ref="tooltip"
    rel="nofollow"
    class="ci-action-icon-wrapper js-ci-status-icon"
    data-toggle="tooltip"
    data-container="body"
    v-html="actionIconSvg"
    aria-label="Job's action">
  </a>
</template>
