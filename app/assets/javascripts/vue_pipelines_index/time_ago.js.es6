/* global Vue, gl */
/* eslint-disable no-param-reassign */
((gl) => {
  gl.VueTimeAgo = Vue.extend({
    props: [
      'pipeline',
    ],
    methods: {
      formatSection(section) {
        if (`${section}`.split('').length <= 1) return `0${section}`;
        return `${section}`;
      },
      hours(date) {
        return this.formatSection(date.getHours());
      },
      minutes(date) {
        return this.formatSection(date.getMinutes());
      },
      seconds(date) {
        return this.formatSection(date.getSeconds());
      },
    },
    computed: {
      finishdate() {
        const date = new Date(
          new Date(
            this.pipeline.details.finished_at
          ).getTime() - new Date(
            this.pipeline.started_at
          ).getTime()
        );
        return (
          `${this.hours(date)}:${this.minutes(date)}:${this.seconds(date)}`
        );
      },
      runningdate() {
        const date = new Date(
          new Date().getTime() - new Date(this.pipeline.started_at).getTime()
        );
        return (
          `${this.hours(date)}:${this.minutes(date)}:${this.seconds(date)}`
        );
      },
      timeStopped() {
        const options = {
          weekday: 'long',
          year: 'numeric',
          month: 'short',
          day: 'numeric',
        };

        options.timeZoneName = 'short';

        const finished = this.pipeline.details.finished_at;

        if (!finished) return false;

        return {
          words: gl.utils.getTimeago().format(finished),
        };
      },
      duration() {
        if (this.timeStopped) return this.finishdate;
        return this.runningdate;
      },
    },
    template: `
      <td>
        <p class="duration">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            width="40"
            height="40"
            viewBox="0 0 40 40"
          >
            <g fill="#8F8F8F" fill-rule="evenodd">
              <path d="M29.513 10.134A15.922 15.922 0 0 0 23 7.28V6h2.993C26.55 6 27 5.552 27 5V2a1 1 0 0 0-1.007-1H14.007C13.45 1 13 1.448 13 2v3a1 1 0 0 0 1.007 1H17v1.28C9.597 8.686 4 15.19 4 23c0 8.837 7.163 16 16 16s16-7.163 16-16c0-3.461-1.099-6.665-2.967-9.283l1.327-1.58a2.498 2.498 0 0 0-.303-3.53 2.499 2.499 0 0 0-3.528.315l-1.016 1.212zM20 34c6.075 0 11-4.925 11-11s-4.925-11-11-11S9 16.925 9 23s4.925 11 11 11z"></path><path d="M19 21h-4.002c-.552 0-.998.452-.998 1.01v1.98c0 .567.447 1.01.998 1.01h7.004c.274 0 .521-.111.701-.291a.979.979 0 0 0 .297-.704v-8.01c0-.54-.452-.995-1.01-.995h-1.98a.997.997 0 0 0-1.01.995V21z"></path>
            </g>
          </svg>
          {{duration}}
        </p>
        <p class="finished-at" v-if='timeStopped'>
          <i class="fa fa-calendar"></i>
          <time
            data-toggle="tooltip"
            data-placement="top"
            data-container="body"
            :data-original-title='9 + 9'
          >
            {{timeStopped.words}}
          </time>
        </p>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
