import getCiStatusSvg from '../../vue_shared/utils/get_ci_status_svg';

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
    },
    borderless: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ciStatusClasses() {
      return `ci-status ci-${this.status}`;
    },
    statusSvg() {
      return getCiStatusSvg({
        status: this.status,
        borderless: this.borderless,
      });
    },
    // appends the status string to the svg by default
    iconSvg() {
      return `${this.statusSvg}${this.status}`;
    },
  },
  template: `
      <a 
        v-html="iconSvg"
        :href="href"
        :class="ciStatusClasses">
      </a>
  `,
};
