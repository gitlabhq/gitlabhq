import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import { parseRailsFormFields } from '~/lib/utils/forms';
import { parseBoolean } from '~/lib/utils/common_utils';
import GroupNameAndPath from './components/group_name_and_path.vue';

Vue.use(VueApollo);

export const initGroupNameAndPath = () => {
  const elements = document.querySelectorAll('.js-group-name-and-path');

  if (!elements.length) {
    return;
  }

  elements.forEach((element) => {
    const fields = parseRailsFormFields(element);
    const { basePath, newSubgroup, mattermostEnabled } = element.dataset;

    return initVueApp({
      el: element,
      name: 'GroupNameAndPathRoot',
      apolloProvider: new VueApollo({
        defaultClient: createDefaultClient(),
      }),
      provide: {
        fields,
        basePath,
        newSubgroup: parseBoolean(newSubgroup),
        mattermostEnabled: parseBoolean(mattermostEnabled),
      },
      component: GroupNameAndPath,
    });
  });
};
