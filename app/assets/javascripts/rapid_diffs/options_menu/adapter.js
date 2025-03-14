import Vue from 'vue';
import { GlDisclosureDropdown } from '@gitlab/ui';

function getMenuItems(container) {
  return JSON.parse(container.querySelector('script').textContent);
}

export const OptionsMenuAdapter = {
  clicks: {
    toggleOptionsMenu(event) {
      const button = event.target.closest('.js-options-button');
      const menuContainer = button.parentElement;
      const items = getMenuItems(menuContainer);

      if (!this.sink.optionsMenu) {
        this.sink.optionsMenu = new Vue({
          el: Vue.version.startsWith('2') ? button : menuContainer,
          name: 'GlDisclosureDropdown',
          render: (createElement = Vue.h) =>
            createElement(GlDisclosureDropdown, {
              props: {
                icon: 'ellipsis_v',
                startOpened: true,
                noCaret: true,
                category: 'tertiary',
                size: 'small',
                items,
              },
            }),
        });
      }
    },
  },
};
