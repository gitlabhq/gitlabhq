/**
 * An instance in deploy board is represented by a square in this mockup:
 * https://gitlab.com/gitlab-org/gitlab-ce/uploads/2f655655c0eadf655d0ae7467b53002a/environments__deploy-graphic.png
 *
 * Each instance has a state and a tooltip.
 * The state needs to be represented in different colors,
 * see more information about this in https://gitlab.com/gitlab-org/gitlab-ee/uploads/5fff049fd88336d9ee0c6ef77b1ba7e3/monitoring__deployboard--key.png
 *
 */

module.exports = {

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
  },

  computed: {
    cssClass() {
      return `deploy-board-instance-${this.status}`;
    },
  },

  template: `
    <div
      class="deploy-board-instance has-tooltip"
      :class="cssClass"
      :data-title="tooltipText"
      data-toggle="tooltip"
      data-placement="top">
    </div>
  `,
};
