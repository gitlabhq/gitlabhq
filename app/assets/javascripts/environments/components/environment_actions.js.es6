/*= require vue */
/* global Vue */

(() => {
  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};

  gl.environmentsList.ActionsComponent = Vue.component('actions-component', {
    props: {
      actions: {
        type: Array,
        required: false,
        default: () => [],
      },

      playIconSvg: {
        type: String,
        required: false,
      },
    },

    template: `
      <div class="inline">
        <div class="dropdown">
          <a class="dropdown-new btn btn-default" data-toggle="dropdown">
            <span class="js-dropdown-play-icon-container" v-html="playIconSvg"></span>
            <i class="fa fa-caret-down"></i>
          </a>

          <ul class="dropdown-menu dropdown-menu-align-right">
            <li v-for="action in actions">
              <a :href="action.play_path"
                data-method="post"
                rel="nofollow"
                class="js-manual-action-link">

                <span class="js-action-play-icon-container" v-html="playIconSvg"></span>

                <span>
                  {{action.name}}
                </span>
              </a>
            </li>
          </ul>
        </div>
      </div>
    `,
  });
})();
