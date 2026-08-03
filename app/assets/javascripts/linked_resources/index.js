import Vue from 'vue';
import VueApollo from 'vue-apollo';
import ResourceLinksBlock from 'ee_component/linked_resources/components/resource_links_block.vue';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';

Vue.use(VueApollo);

export default function initLinkedResources() {
  const linkedResourcesRootElement = document.querySelector('.js-linked-resources-root');

  if (linkedResourcesRootElement) {
    const { issuableId, canAddResourceLinks } = linkedResourcesRootElement.dataset;

    const apolloProvider = new VueApollo({
      defaultClient: createDefaultClient(),
    });

    initVueApp({
      el: linkedResourcesRootElement,
      name: 'LinkedResourcesRoot',
      apolloProvider,
      component: ResourceLinksBlock,
      props: {
        issuableId: parseInt(issuableId, 10),
        canAddResourceLinks: parseBoolean(canAddResourceLinks),
      },
    });
  }
}
