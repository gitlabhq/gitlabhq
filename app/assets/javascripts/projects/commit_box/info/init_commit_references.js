import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import createDefaultClient from '~/lib/graphql';
import CommitBranches from './components/commit_refs.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default (selector = 'js-commit-branches-and-tags') => {
  const el = document.getElementById(selector);

  if (!el) {
    return false;
  }

  const { fullPath, commitSha } = el.dataset;

  return initVueApp({
    el,
    name: 'CommitBranchesRoot',
    apolloProvider,
    provide: {
      fullPath,
      commitSha,
    },
    component: CommitBranches,
  });
};
