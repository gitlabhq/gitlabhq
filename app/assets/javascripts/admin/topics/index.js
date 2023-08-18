import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import RemoveAvatar from './components/remove_avatar.vue';
import MergeTopics from './components/merge_topics.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initRemoveAvatar = () => {
  const el = document.querySelector('.js-remove-topic-avatar');

  if (!el) {
    return false;
  }

  const { path, name } = el.dataset;

  return new Vue({
    el,
    provide: {
      path,
      name,
    },
    render(h) {
      return h(RemoveAvatar);
    },
  });
};

export const initMergeTopics = () => {
  const el = document.querySelector('.js-merge-topics');

  if (!el) return false;

  const { path } = el.dataset;

  return new Vue({
    el,
    apolloProvider,
    provide: { path },
    render(createElement) {
      return createElement(MergeTopics);
    },
  });
};
