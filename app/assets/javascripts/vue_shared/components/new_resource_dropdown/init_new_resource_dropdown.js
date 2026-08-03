import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import NewResourceDropdown from './new_resource_dropdown.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initNewResourceDropdown = (props = {}) => {
  const el = document.querySelector('.js-new-resource-dropdown');

  if (!el) {
    return false;
  }

  const { groupId, fullPath, username } = el.dataset;

  return initVueApp({
    el,
    name: 'NewResourceDropdownRoot',
    apolloProvider,
    component: NewResourceDropdown,
    props: {
      groupId,
      queryVariables: {
        ...(fullPath
          ? {
              fullPath,
            }
          : {}),
        ...(username
          ? {
              username,
            }
          : {}),
      },
      ...props,
    },
  });
};
