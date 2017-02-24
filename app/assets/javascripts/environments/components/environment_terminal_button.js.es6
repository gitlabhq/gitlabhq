/**
 * Renders a terminal button to open a web terminal.
 * Used in environments table.
 */
const Vue = require('vue');
const terminalIconSvg = require('../../../../views/shared/icons/_icon_terminal.svg');

module.exports = Vue.component('terminal-button-component', {
  props: {
    terminalPath: {
      type: String,
      default: '',
    },
  },

  data() {
    return { terminalIconSvg };
  },

  template: `
    <a class="btn terminal-button"
      :href="terminalPath">
      <span class="js-terminal-icon-container" v-html="terminalIconSvg"></span>
    </a>
  `,
});
