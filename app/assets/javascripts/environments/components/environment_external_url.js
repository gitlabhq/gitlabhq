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
      class="btn external_url"
      :href="externalUrl"
      target="_blank"
      title="Environment external URL">
      <i class="fa fa-external-link" aria-hidden="true"></i>
    </a>
  `,
};
