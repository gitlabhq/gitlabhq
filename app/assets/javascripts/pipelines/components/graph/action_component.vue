<script>
  import getActionIcon from '../../../vue_shared/ci_action_icons';
  import tooltip from '../../../vue_shared/directives/tooltip';

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

    directives: {
      tooltip,
    },

    computed: {
      actionIconSvg() {
        return getActionIcon(this.actionIcon);
      },

      cssClass() {
        return `js-${gl.text.dasherize(this.actionIcon)}`;
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
    class="ci-action-icon-container"
    data-container="body">

    <i
      class="ci-action-icon-wrapper"
      :class="cssClass"
      v-html="actionIconSvg"
      aria-hidden="true"
      />
  </a>
</template>
