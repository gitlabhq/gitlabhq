/**
 * Renders a terminal button to open a web terminal.
 * Used in environments table.
 */
import terminalIconSvg from 'icons/_icon_terminal.svg';

export default {
  props: {
    terminalPath: {
      type: String,
      required: false,
      default: '',
    },
  },

  data() {
    return { terminalIconSvg };
  },

  template: `
    <a class="btn terminal-button"
      title="Open web terminal"
      :href="terminalPath">
      ${terminalIconSvg}
    </a>
  `,
};
