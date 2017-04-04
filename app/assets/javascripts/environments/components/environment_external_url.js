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

  computed: {
    title() {
      return 'Open';
    },
  },

  template: `
    <a
      class="btn external-url has-tooltip"
      data-container="body"
      :href="externalUrl"
      target="_blank"
      rel="noopener noreferrer nofollow"
      :title="title"
      :aria-label="title">
      <i class="fa fa-external-link" aria-hidden="true"></i>
    </a>
  `,
};
