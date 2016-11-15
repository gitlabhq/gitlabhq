/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueStage = Vue.extend({
    components: {
      'running-icon': gl.VueRunningIcon,
      'pending-icon': gl.VuePendingIcon,
      'failed-icon': gl.VueFailedIcon,
      'success-icon': gl.VueSuccessIcon,
      'created-icon': gl.VueCreatedIcon,
      'canceled-icon': gl.VueCanceledIcon,
    },
    props: ['stage'],
    computed: {
      buildStatus() {
        return `Build: ${this.stage.status}`;
      },
      tooltip() {
        return `has-tooltip ci-status-icon-${this.stage.status}`;
      },
    },
    template: `
      <a
        :class='tooltip'
        :title='buildStatus'
        :href='stage.url'
      >
        <running-icon v-if='stage.status === "running"'></running-icon>
        <success-icon v-if='stage.status === "success"'></success-icon>
        <failed-icon v-if='stage.status === "failed"'></failed-icon>
        <pending-icon v-if='stage.status === "pending"'></pending-icon>
        <created-icon v-if='stage.status === "created"'></created-icon>
        <canceled-icon v-if='stage.status === "canceled"'></canceled-icon>
      </a>
    `,
  });
})(window.gl || (window.gl = {}));
