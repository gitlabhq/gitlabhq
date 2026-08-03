import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import DiffStatsDropdown from '~/vue_shared/components/diff_stats_dropdown.vue';

export const initDiffStatsDropdown = () => {
  const el = document.querySelector('.js-diff-stats-dropdown');

  if (!el) {
    return false;
  }

  const { changed, added, deleted, files } = el.dataset;

  return initVueApp({
    el,
    name: 'DiffStatsDropdownRoot',
    component: DiffStatsDropdown,
    props: {
      changed: parseInt(changed, 10),
      added: parseInt(added, 10),
      deleted: parseInt(deleted, 10),
      files: JSON.parse(files),
    },
  });
};
