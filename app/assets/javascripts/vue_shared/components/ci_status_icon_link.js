import { getCiStatusSvg, normalizeStatus } from '../../vue_shared/utils/get_ci_status_svg';

export default {
  name: 'CIStatusIconLink',
  props: {
    status: {
      type: String,
      required: true,
    },
    href: {
      type: String,
      required: false,
      default: '',
    },
    borderless: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    statusText() {
      return normalizeStatus(this.status);
    },
    statusCss() {
      return `ci-status ci-${this.statusText}`;
    },
    statusSvg() {
      return getCiStatusSvg({
        status: this.status,
        borderless: this.borderless,
      });
    },
    // appends the status string to the svg by default. These
    // may need to be decoupled at some point
    iconSvg() {
      return `${this.statusSvg}${this.statusText}`;
    },
  },
  template: `
      <a 
        v-html="iconSvg"
        :href="href"
        :class="statusCss">
      </a>
  `,
};
