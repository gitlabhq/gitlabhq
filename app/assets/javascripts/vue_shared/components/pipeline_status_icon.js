import { statusClassToSvgMap } from '../pipeline_svg_icons';

export default {
  name: 'PipelineStatusIcon',
  props: {
    pipelineStatus: { type: Object, required: true, default: () => ({}) },
  },
  computed: {
    svg() {
      return statusClassToSvgMap[this.pipelineStatus.icon];
    },
    statusClass() {
      return `ci-status-icon ci-status-icon-${this.pipelineStatus.group}`;
    },
  },
  template: `
    <div :class="statusClass">
      <a class="icon-link" :href="pipelineStatus.details_path">
        <span v-html="svg" aria-hidden="true"></span>
      </a>
    </div>
  `,
};
