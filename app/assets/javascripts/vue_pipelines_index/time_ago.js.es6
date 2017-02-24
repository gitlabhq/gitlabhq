/* global Vue, gl */
/* eslint-disable no-param-reassign */

window.Vue = require('vue');
require('../lib/utils/datetime_utility');

const iconTimerSvg = require('../../../views/shared/icons/_icon_timer.svg');

((gl) => {
  gl.VueTimeAgo = Vue.extend({
    data() {
      return {
        currentTime: new Date(),
        iconTimerSvg,
      };
    },
    props: ['pipeline'],
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
      duration() {
        const { duration } = this.pipeline.details;
        const date = new Date(duration * 1000);

        let hh = date.getUTCHours();
        let mm = date.getUTCMinutes();
        let ss = date.getSeconds();

        if (hh < 10) hh = `0${hh}`;
        if (mm < 10) mm = `0${mm}`;
        if (ss < 10) ss = `0${ss}`;

        if (duration !== null) return `${hh}:${mm}:${ss}`;
        return false;
      },
    },
    methods: {
      changeTime() {
        this.currentTime = new Date();
      },
    },
    template: `
      <td>
        <p class="duration" v-if='duration'>
          <span v-html="iconTimerSvg"></span>
          {{duration}}
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
