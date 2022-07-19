import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlToast } from '@gitlab/ui';
import createDefaultClient from '~/lib/graphql';
import WorkItemLinks from './work_item_links.vue';

Vue.use(VueApollo);
Vue.use(GlToast);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default function initWorkItemLinks() {
  if (!window.gon.features.workItemsHierarchy) {
    return;
  }

  const workItemLinksRoot = document.querySelector('.js-work-item-links-root');

  if (!workItemLinksRoot) {
    return;
  }

  // eslint-disable-next-line no-new
  new Vue({
    el: workItemLinksRoot,
    name: 'WorkItemLinksRoot',
    apolloProvider,
    components: {
      workItemLinks: WorkItemLinks,
    },
    provide: {
      projectPath: workItemLinksRoot.dataset.projectPath,
    },
    render: (createElement) =>
      createElement('work-item-links', {
        props: {
          issuableId: parseInt(workItemLinksRoot.dataset.issuableId, 10),
        },
      }),
  });
}
