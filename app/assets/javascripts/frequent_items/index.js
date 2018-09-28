import $ from 'jquery';
import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import eventHub from '~/frequent_items/event_hub';
import frequentItems from './components/app.vue';

Vue.use(Translate);

const frequentItemDropdowns = [
  {
    namespace: 'projects',
    key: 'project',
  },
  {
    namespace: 'groups',
    key: 'group',
  },
];

document.addEventListener('DOMContentLoaded', () => {
  frequentItemDropdowns.forEach(dropdown => {
    const { namespace, key } = dropdown;
    const el = document.getElementById(`js-${namespace}-dropdown`);
    const navEl = document.getElementById(`nav-${namespace}-dropdown`);

    // Don't do anything if element doesn't exist (No groups dropdown)
    // This is for when the user accesses GitLab without logging in
    if (!el || !navEl) {
      return;
    }

    $(navEl).on('shown.bs.dropdown', () => {
      eventHub.$emit(`${namespace}-dropdownOpen`);
    });

    // eslint-disable-next-line no-new
    new Vue({
      el,
      components: {
        frequentItems,
      },
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
        return createElement('frequent-items', {
          props: {
            namespace,
            currentUserName: this.currentUserName,
            currentItem: this.currentItem,
          },
        });
      },
    });
  });
});
