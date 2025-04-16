import Vue from 'vue';
import { GlDisclosureDropdown } from '@gitlab/ui';

function getMenuItems(container) {
  return JSON.parse(container.querySelector('script').textContent);
}

export const OptionsMenuAdapter = {
  clicks: {
    toggleOptionsMenu(event, button) {
      const menuContainer = this.diffElement.querySelector('[data-options-menu]');
      const items = getMenuItems(menuContainer);
      // eslint-disable-next-line no-new
      new Vue({
        el: Vue.version.startsWith('2') ? button : menuContainer,
        name: 'GlDisclosureDropdown',
        render(h) {
          return h(GlDisclosureDropdown, {
            props: {
              icon: 'ellipsis_v',
              startOpened: true,
              noCaret: true,
              category: 'tertiary',
              size: 'small',
              items,
            },
            attrs: {
              'data-options-toggle': true,
            },
          });
        },
      });
    },
  },
};
