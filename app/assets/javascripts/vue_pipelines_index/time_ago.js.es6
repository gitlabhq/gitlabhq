/* global Vue, gl */
/* eslint-disable no-param-reassign */

((gl) => {
  gl.VueTimeAgo = Vue.extend({
    data() {
      return {
        currentTime: new Date(),
      };
    },
    props: ['pipeline', 'svgs'],
    computed: {
      timeAgo() {
        return gl.utils.getTimeago();
      },
      localTimeFinished() {
        return gl.utils.formatDate(this.pipeline.details.finished_at);
      },
      timeStopped() {
        const changeTime = this.currentTime;
        const options = {
          weekday: 'long',
          year: 'numeric',
          month: 'short',
          day: 'numeric',
        };
        options.timeZoneName = 'short';
        const finished = this.pipeline.details.finished_at;
        if (!finished && changeTime) return false;
        return ({ words: this.timeAgo.format(finished) });
      },
    },
    methods: {
      duration() {
        const { duration } = this.pipeline.details;
        if (duration === 0) return '00:00:00';
        if (duration !== null) return duration;
        return false;
      },
      changeTime() {
        this.currentTime = new Date();
      },
    },
    template: `
      <td>
        <p class="duration" v-if='duration()'>
          <span v-html='svgs.iconTimer'></span>
          {{duration()}}
        </p>
        <p class="finished-at" v-if='timeStopped'>
          <i class="fa fa-calendar"></i>
          <time
            data-toggle="tooltip"
            data-placement="top"
            data-container="body"
            :data-original-title='localTimeFinished'
          >
            {{timeStopped.words}}
          </time>
        </p>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
