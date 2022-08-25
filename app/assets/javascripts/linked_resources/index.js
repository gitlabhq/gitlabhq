import Vue from 'vue';
import VueApollo from 'vue-apollo';
import ResourceLinksBlock from 'ee_component/linked_resources/components/resource_links_block.vue';
import createDefaultClient from '~/lib/graphql';
import { parseBoolean } from '~/lib/utils/common_utils';

Vue.use(VueApollo);

export default function initLinkedResources() {
  const linkedResourcesRootElement = document.querySelector('.js-linked-resources-root');

  if (linkedResourcesRootElement) {
    const { issuableId, canAddResourceLinks, helpPath } = linkedResourcesRootElement.dataset;

    const apolloProvider = new VueApollo({
      defaultClient: createDefaultClient(),
    });

    // eslint-disable-next-line no-new
    new Vue({
      el: linkedResourcesRootElement,
      name: 'LinkedResourcesRoot',
      apolloProvider,
      components: {
        ResourceLinksBlock,
      },
      render: (createElement) =>
        createElement('resource-links-block', {
          props: {
            helpPath,
            issuableId: parseInt(issuableId, 10),
            canAddResourceLinks: parseBoolean(canAddResourceLinks),
          },
        }),
    });
  }
}
