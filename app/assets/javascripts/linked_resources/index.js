import Vue from 'vue';
import ResourceLinksBlock from 'ee_component/linked_resources/components/resource_links_block.vue';
import { parseBoolean } from '~/lib/utils/common_utils';

export default function initLinkedResources() {
  const linkedResourcesRootElement = document.querySelector('.js-linked-resources-root');

  if (linkedResourcesRootElement) {
    const { issuableId, canAddResourceLinks, helpPath } = linkedResourcesRootElement.dataset;

    // eslint-disable-next-line no-new
    new Vue({
      el: linkedResourcesRootElement,
      name: 'LinkedResourcesRoot',
      components: {
        resourceLinksBlock: ResourceLinksBlock,
      },
      render: (createElement) =>
        createElement('resource-links-block', {
          props: {
            issuableId,
            helpPath,
            canAddResourceLinks: parseBoolean(canAddResourceLinks),
          },
        }),
    });
  }
}
