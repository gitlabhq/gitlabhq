/* global Vue, gl */
/* eslint-disable no-param-reassign */

import canceledSvg from '../../../views/shared/icons/_icon_status_canceled.svg';
import createdSvg from '../../../views/shared/icons/_icon_status_created.svg';
import failedSvg from '../../../views/shared/icons/_icon_status_failed.svg';
import manualSvg from '../../../views/shared/icons/_icon_status_manual.svg';
import pendingSvg from '../../../views/shared/icons/_icon_status_pending.svg';
import runningSvg from '../../../views/shared/icons/_icon_status_running.svg';
import skippedSvg from '../../../views/shared/icons/_icon_status_skipped.svg';
import successSvg from '../../../views/shared/icons/_icon_status_success.svg';
import warningSvg from '../../../views/shared/icons/_icon_status_warning.svg';

((gl) => {
  gl.VueStatusScope = Vue.extend({
    props: [
      'pipeline',
    ],

    data() {
      const svgsDictionary = {
        icon_status_canceled: canceledSvg,
        icon_status_created: createdSvg,
        icon_status_failed: failedSvg,
        icon_status_manual: manualSvg,
        icon_status_pending: pendingSvg,
        icon_status_running: runningSvg,
        icon_status_skipped: skippedSvg,
        icon_status_success: successSvg,
        icon_status_warning: warningSvg,
      };

      return {
        svg: svgsDictionary[this.pipeline.details.status.icon],
      };
    },

    computed: {
      cssClasses() {
        const cssObject = { 'ci-status': true };
        cssObject[`ci-${this.pipeline.details.status.group}`] = true;
        return cssObject;
      },

      detailsPath() {
        const { status } = this.pipeline.details;
        return status.has_details ? status.details_path : false;
      },
    },
    template: `
      <td class="commit-link">
        <a
          :class='cssClasses'
          :href='detailsPath'
          v-html="svg + pipeline.details.status.text">
        </a>
      </td>
    `,
  });
})(window.gl || (window.gl = {}));
