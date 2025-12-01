import Vue from 'vue';
import DiffFileOptionsDropdown from '~/rapid_diffs/app/options_menu/diff_file_options_dropdown.vue';

function getMenuItems(container) {
  return JSON.parse(container.querySelector('script').textContent);
}

export const optionsMenuAdapter = {
  clicks: {
    toggleOptionsMenu(event, button) {
      const menuContainer = this.diffElement.querySelector('[data-options-menu]');
      if (!menuContainer) return;
      const items = getMenuItems(menuContainer);
      // eslint-disable-next-line no-new
      new Vue({
        el: Vue.version.startsWith('2') ? button : menuContainer,
        name: 'GlDisclosureDropdown',
        render(h) {
          return h(DiffFileOptionsDropdown, { props: { items } });
        },
      });
    },
  },
};
