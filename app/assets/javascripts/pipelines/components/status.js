import canceledSvg from 'icons/_icon_status_canceled.svg';
import createdSvg from 'icons/_icon_status_created.svg';
import failedSvg from 'icons/_icon_status_failed.svg';
import manualSvg from 'icons/_icon_status_manual.svg';
import pendingSvg from 'icons/_icon_status_pending.svg';
import runningSvg from 'icons/_icon_status_running.svg';
import skippedSvg from 'icons/_icon_status_skipped.svg';
import successSvg from 'icons/_icon_status_success.svg';
import warningSvg from 'icons/_icon_status_warning.svg';

export default {
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },

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
      return `ci-status ci-${this.pipeline.details.status.group}`;
    },

    detailsPath() {
      const { status } = this.pipeline.details;
      return status.has_details ? status.details_path : false;
    },

    content() {
      return `${this.svg} ${this.pipeline.details.status.text}`;
    },
  },
  template: `
    <td class="commit-link">
      <a
        :class="cssClasses"
        :href="detailsPath"
        v-html="content">
      </a>
    </td>
  `,
};
