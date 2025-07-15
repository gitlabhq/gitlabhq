import Vue from 'vue';
import { GlDisclosureDropdown } from '@gitlab/ui';
import { s__ } from '~/locale';

function getMenuItems(container) {
  return JSON.parse(container.querySelector('script').textContent);
}

export const OptionsMenuAdapter = {
  clicks: {
    toggleOptionsMenu(event, button) {
      const menuContainer = this.diffElement.querySelector('[data-options-menu]');
      if (!menuContainer) return;
      const items = getMenuItems(menuContainer);
      // eslint-disable-next-line no-new
      new Vue({
        el: Vue.version.startsWith('2') ? button : menuContainer,
        name: 'GlDisclosureDropdown',
        mounted() {
          const toggle = this.$el.querySelector('button');
          toggle.focus();
          // .focus() initiates additional transition which we don't need
          toggle.style.transition = 'none';
          requestAnimationFrame(() => {
            toggle.style.transition = '';
          });
        },
        render(h) {
          return h(GlDisclosureDropdown, {
            props: {
              icon: 'ellipsis_v',
              startOpened: true,
              noCaret: true,
              category: 'tertiary',
              size: 'small',
              items,
              toggleText: s__('RapidDiffs|Show options'),
              textSrOnly: true,
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
