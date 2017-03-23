/**
 * Renders the external url link in environments table.
 */
export default {
  props: {
    externalUrl: {
      type: String,
      default: '',
    },
  },

  template: `
    <a
      class="btn external_url has-tooltip"
      :href="externalUrl"
      target="_blank"
      rel="noopener noreferrer"
      title="Open Environment">
      <i class="fa fa-external-link" aria-hidden="true"></i>
    </a>
  `,
};
