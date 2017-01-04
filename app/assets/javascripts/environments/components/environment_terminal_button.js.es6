/*= require vue */
/* global Vue */

(() => {
  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};

  window.gl.environmentsList.TerminalButtonComponent = Vue.component('terminal-button-component', {
    props: {
      terminalPath: {
        type: String,
        default: '',
      },
      terminalIconSvg: {
        type: String,
        default: '',
      },
    },

    template: `
      <a class="btn terminal-button"
        :href="terminalPath">
        <span class="js-terminal-icon-container" v-html="terminalIconSvg"></span>
      </a>
    `,
  });
})();
