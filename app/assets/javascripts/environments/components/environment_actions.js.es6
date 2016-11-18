/*= require vue */
/* global Vue */

(() => {
  window.gl = window.gl || {};
  window.gl.environmentsList = window.gl.environmentsList || {};

  window.gl.environmentsList.ActionsComponent = Vue.component('actions-component', {
    props: {
      actions: {
        type: Array,
        required: false,
        default: () => [],
      },
    },

    /**
     * Appends the svg icon that were render in the index page.
     * In order to reuse the svg instead of copy and paste in this template
     * we need to render it outside this component using =custom_icon partial.
     *
     * TODO: Remove this when webpack is merged.
     *
     */
    mounted() {
      // const playIcon = document.querySelector('.play-icon-svg.hidden svg');
      //
      // const dropdownContainer = this.$el.querySelector('.dropdown-play-icon-container');
      // const actionContainers = this.$el.querySelectorAll('.action-play-icon-container');
      // // Phantomjs does not have support to iterate a nodelist.
      // const actionsArray = [].slice.call(actionContainers);
      //
      // if (playIcon && actionsArray && dropdownContainer) {
      //   dropdownContainer.appendChild(playIcon.cloneNode(true));
      //
      //   actionsArray.forEach((element) => {
      //     element.appendChild(playIcon.cloneNode(true));
      //   });
      // }
    },

    template: `
      <div class="inline">
        <div class="dropdown">
          <a class="dropdown-new btn btn-default" data-toggle="dropdown">
            <slot name="actionplayicon"></slot>
            <i class="fa fa-caret-down"></i>
          </a>

          <ul class="dropdown-menu dropdown-menu-align-right">
            <li v-for="action in actions">
              <a :href="action.play_path"
                data-method="post"
                rel="nofollow"
                class="js-manual-action-link">
                <slot name="actionplayicon"></slot>
                <span v-html="action.name"></span>
              </a>
            </li>
          </ul>
        </div>
      </div>
    `,
  });
})();
