import { defaultDataIdFromObject } from '@apollo/client/core';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import TerraformList from './components/terraform_list.vue';
import resolvers from './graphql/resolvers';

Vue.use(VueApollo);

export default () => {
  const el = document.querySelector('#js-terraform-list');

  if (!el) {
    return null;
  }

  const defaultClient = createDefaultClient(resolvers, {
    cacheConfig: {
      dataIdFromObject: (object) => {
        return object.id || defaultDataIdFromObject(object);
      },
    },
  });

  const { emptyStateImage, projectPath, accessTokensPath, terraformApiUrl, username } = el.dataset;

  return initVueApp({
    el,
    name: 'TerraformListRoot',
    apolloProvider: new VueApollo({ defaultClient }),
    provide: {
      projectPath,
      accessTokensPath,
      terraformApiUrl,
      username,
    },
    component: TerraformList,
    props: {
      emptyStateImage,
      terraformAdmin: Object.prototype.hasOwnProperty.call(el.dataset, 'terraformAdmin'),
    },
  });
};
