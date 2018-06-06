<script>
  /**
   * An instance in deploy board is represented by a square in this mockup:
   * https://gitlab.com/gitlab-org/gitlab-ce/uploads/2f655655c0eadf655d0ae7467b53002a/environments__deploy-graphic.png
   *
   * Each instance has a state and a tooltip.
   * The state needs to be represented in different colors,
   * see more information about this in
   * https://gitlab.com/gitlab-org/gitlab-ee/uploads/5fff049fd88336d9ee0c6ef77b1ba7e3/monitoring__deployboard--key.png
   *
   * An instance can represent a normal deploy or a canary deploy. In the latter we need to provide
   * this information in the tooltip and the colors.
   * Mockup is https://gitlab.com/gitlab-org/gitlab-ee/merge_requests/1551#note_26595150
   */
  import tooltip from '~/vue_shared/directives/tooltip';

  export default {
    directives: {
      tooltip,
    },

    props: {
      /**
       * Represents the status of the pod. Each state is represented with a different
       * color.
       * It should be one of the following:
       * finished || deploying || failed || ready || preparing || waiting
       */
      status: {
        type: String,
        required: true,
        default: 'finished',
      },

      tooltipText: {
        type: String,
        required: false,
        default: '',
      },

      stable: {
        type: Boolean,
        required: false,
        default: true,
      },

      podName: {
        type: String,
        required: false,
        default: '',
      },

      logsPath: {
        type: String,
        required: true,
      },
    },

    computed: {
      cssClass() {
        let cssClassName = `deploy-board-instance-${this.status}`;

        if (!this.stable) {
          cssClassName = `${cssClassName} deploy-board-instance-canary`;
        }

        return cssClassName;
      },

      computedLogPath() {
        return `${this.logsPath}?pod_name=${this.podName}`;
      },
    },
  };
</script>
<template>
  <a
    v-tooltip
    class="deploy-board-instance"
    :class="cssClass"
    :data-title="tooltipText"
    data-placement="top"
    :href="computedLogPath"
  >
  </a>
</template>
