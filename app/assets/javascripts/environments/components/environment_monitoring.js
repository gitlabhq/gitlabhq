/**
 * Renders the Monitoring (Metrics) link in environments table.
 */
export default {
  props: {
    monitoringUrl: {
      type: String,
      default: '',
      required: true,
    },
  },

  computed: {
    title() {
      return 'Monitoring';
    },
  },

  template: `
    <a
      class="btn monitoring-url has-tooltip"
      data-container="body"
      :href="monitoringUrl"
      rel="noopener noreferrer nofollow"
      :title="title"
      :aria-label="title">
      <i class="fa fa-area-chart" aria-hidden="true"></i>
    </a>
  `,
};
