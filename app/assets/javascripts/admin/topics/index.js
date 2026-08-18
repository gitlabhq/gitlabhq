import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
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

  return initVueApp({
    el,
    name: 'RemoveAvatarRoot',
    provide: {
      path,
      name,
    },
    component: RemoveAvatar,
  });
};

export const initMergeTopics = () => {
  const el = document.querySelector('.js-merge-topics');

  if (!el) return false;

  const { path } = el.dataset;

  return initVueApp({
    el,
    name: 'MergeTopicsRoot',
    apolloProvider,
    provide: { path },
    component: MergeTopics,
  });
};
