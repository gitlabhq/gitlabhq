import Vue from 'vue';
import { GlDisclosureDropdown } from '@gitlab/ui';

export const OptionsMenuAdapter = {
  clicks: {
    toggleOptionsMenu(event) {
      const button = event.target.closest('.js-options-button');

      if (!this.sink.optionsMenu) {
        this.sink.optionsMenu = new Vue({
          el: Vue.version.startsWith('2') ? button : button.parentElement,
          name: 'GlDisclosureDropdown',
          render: (createElement = Vue.h) =>
            createElement(GlDisclosureDropdown, {
              props: {
                icon: 'ellipsis_v',
                startOpened: true,
                noCaret: true,
                category: 'tertiary',
                size: 'small',
              },
            }),
        });
      }
    },
  },
};
