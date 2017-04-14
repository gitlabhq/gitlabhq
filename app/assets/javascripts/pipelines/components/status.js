import CiStatusIconLink from '../../vue_shared/components/ci_status_icon_link';

export default {
  props: {
    pipeline: {
      type: Object,
      required: true,
    },
  },
  components: {
    'ci-status-icon-link': CiStatusIconLink,
  },
  computed: {
    detailsPath() {
      const { status } = this.pipeline.details;
      return status.has_details ? status.details_path : false;
    },
    pipelineStatus() {
      return this.pipeline.details.status.text;
    },
  },
  template: `
    <td class="commit-link">
      <ci-status-icon-link
        :href="detailsPath"
        :status="pipelineStatus"
        :borderless="false"/>
    </td>
  `,
};
