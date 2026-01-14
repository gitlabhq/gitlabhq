import Vue from 'vue';
import ExploreGroupsApp from '~/explore/groups/components/app.vue';

export const initExploreGroups = () => {
  const el = document.getElementById('js-explore-groups');

  if (!el) return null;

  return new Vue({
    el,
    name: 'ExploreGroupsRoot',
    render(createElement) {
      return createElement(ExploreGroupsApp, {});
    },
  });
};
