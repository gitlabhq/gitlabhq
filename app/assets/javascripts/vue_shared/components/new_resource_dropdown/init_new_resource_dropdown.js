import Vue from 'vue';
import VueApollo from 'vue-apollo';
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

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(NewResourceDropdown, {
        props: {
          withLocalStorage: true,
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
    },
  });
};
