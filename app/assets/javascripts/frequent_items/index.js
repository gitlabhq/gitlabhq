import $ from 'jquery';
import Vue from 'vue';
import Vuex from 'vuex';
import { createStore } from '~/frequent_items/store';
import VuexModuleProvider from '~/vue_shared/components/vuex_module_provider.vue';
import Translate from '~/vue_shared/translate';
import { FREQUENT_ITEMS_DROPDOWNS } from './constants';
import eventHub from './event_hub';

Vue.use(Vuex);
Vue.use(Translate);

export default function initFrequentItemDropdowns() {
  const store = createStore();

  FREQUENT_ITEMS_DROPDOWNS.forEach((dropdown) => {
    const { namespace, key, vuexModule } = dropdown;
    const el = document.getElementById(`js-${namespace}-dropdown`);
    const navEl = document.getElementById(`nav-${namespace}-dropdown`);

    // Don't do anything if element doesn't exist (No groups dropdown)
    // This is for when the user accesses GitLab without logging in
    if (!el || !navEl) {
      return;
    }

    import('./components/app.vue')
      .then(({ default: FrequentItems }) => {
        // eslint-disable-next-line no-new
        new Vue({
          el,
          store,
          data() {
            const { dataset } = this.$options.el;
            const item = {
              id: Number(dataset[`${key}Id`]),
              name: dataset[`${key}Name`],
              namespace: dataset[`${key}Namespace`],
              webUrl: dataset[`${key}WebUrl`],
              avatarUrl: dataset[`${key}AvatarUrl`] || null,
              lastAccessedOn: Date.now(),
            };

            return {
              currentUserName: dataset.userName,
              currentItem: item,
            };
          },
          render(createElement) {
            return createElement(
              VuexModuleProvider,
              {
                props: {
                  vuexModule,
                },
              },
              [
                createElement(FrequentItems, {
                  props: {
                    namespace,
                    currentUserName: this.currentUserName,
                    currentItem: this.currentItem,
                    searchClass: 'gl-display-none gl-sm-display-block',
                  },
                }),
              ],
            );
          },
        });
      })
      .catch(() => {});

    $(navEl).on('shown.bs.dropdown', () => {
      eventHub.$emit(`${namespace}-dropdownOpen`);
    });
  });
}
