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

      cssClass() {
        return `js-${gl.text.dasherize(this.actionIcon)}`;
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
    class="ci-action-icon-container"
    data-toggle="tooltip"
    data-container="body">

    <i
      class="ci-action-icon-wrapper"
      :class="cssClass"
      v-html="actionIconSvg"
      aria-hidden="true"
      />
  </a>
</template>
