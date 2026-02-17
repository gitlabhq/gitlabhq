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
        const fileId = this.id;

        // eslint-disable-next-line no-new
        new Vue({
          el: button,
          name: 'DropdownComponentRoot',
          pinia,
          render(h) {
            return h(dropdownComponent, { props: { items, oldPath, newPath, fileId } });
          },
        });
      },
    },
  };
};

export const optionsMenuAdapter = createOptionsMenuAdapter(DiffFileOptionsDropdown);
