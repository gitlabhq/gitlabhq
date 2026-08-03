import { parseBoolean } from '~/lib/utils/common_utils';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import DiscussionCounter from '~/notes/components/discussion_counter.vue';
import { pinia } from '~/pinia/instance';

export function initDiscussionCounter(store) {
  const el = document.getElementById('js-vue-discussion-counter');

  if (el) {
    const { blocksMerge, canResolveDiscussion } = el.dataset;

    initVueApp({
      el,
      name: 'DiscussionCounterApp',
      pinia,
      provide: {
        store,
      },
      component: DiscussionCounter,
      props: {
        blocksMerge: parseBoolean(blocksMerge),
        canResolveDiscussion: parseBoolean(canResolveDiscussion),
        compact: true,
      },
    });
  }
}
