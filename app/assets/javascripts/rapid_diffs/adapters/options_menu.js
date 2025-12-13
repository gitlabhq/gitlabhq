import Vue from 'vue';
import { pinia } from '~/pinia/instance';
import DiffFileOptionsDropdown from '~/rapid_diffs/app/options_menu/diff_file_options_dropdown.vue';

function getMenuItems(container) {
  return JSON.parse(container.querySelector('script').textContent);
}

export const createOptionsMenuAdapter = (dropdownComponent) => {
  return {
    clicks: {
      toggleOptionsMenu(event, button) {
        const menuContainer = this.diffElement.querySelector('[data-options-menu]');
        if (!menuContainer) return;
        const items = getMenuItems(menuContainer);
        const { oldPath, newPath } = this.data;

        // eslint-disable-next-line no-new
        new Vue({
          el: Vue.version.startsWith('2') ? button : menuContainer,
          pinia,
          render(h) {
            return h(dropdownComponent, { props: { items, oldPath, newPath } });
          },
        });
      },
    },
  };
};

export const optionsMenuAdapter = createOptionsMenuAdapter(DiffFileOptionsDropdown);
