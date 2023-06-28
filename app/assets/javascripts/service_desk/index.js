import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { gqlClient } from '~/issues/list/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import ServiceDeskListApp from './components/service_desk_list_app.vue';

export async function mountServiceDeskListApp() {
  const el = document.querySelector('.js-service-desk-list');

  if (!el) {
    return null;
  }

  const { emptyStateSvgPath, fullPath, isProject, isSignedIn } = el.dataset;

  Vue.use(VueApollo);

  return new Vue({
    el,
    name: 'ServiceDeskListRoot',
    apolloProvider: new VueApollo({
      defaultClient: await gqlClient(),
    }),
    provide: {
      emptyStateSvgPath,
      fullPath,
      isProject: parseBoolean(isProject),
      isSignedIn: parseBoolean(isSignedIn),
    },
    render: (createComponent) => createComponent(ServiceDeskListApp),
  });
}
