import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import DiffFileOptionsDropdown from '~/rapid_diffs/app/options_menu/diff_file_options_dropdown.vue';

function getMenuItems(container) {
  return JSON.parse(container.querySelector('script').textContent);
}

export const createOptionsMenuAdapter = (dropdownComponent, store) => {
  return {
    clicks: {
      toggleOptionsMenu(event, button) {
        const menuContainer = this.diffElement.querySelector('[data-options-menu]');
        if (!menuContainer) return;
        const items = getMenuItems(menuContainer);
        const { oldPath, newPath } = this.data;
        const fileId = this.id;

        initVueApp({
          el: button,
          name: 'DropdownComponentRoot',
          provide: { store },
          component: dropdownComponent,
          props: { items, oldPath, newPath, fileId },
        });
      },
    },
  };
};

export const optionsMenuAdapter = createOptionsMenuAdapter(DiffFileOptionsDropdown);
