import Vue from 'vue';
import DiffStatsDropdown from '~/vue_shared/components/diff_stats_dropdown.vue';
import { stickyMonitor } from './lib/utils/sticky';

export const initDiffStatsDropdown = (stickyTop) => {
  if (stickyTop) {
    // We spend quite a bit of effort in our CSS to set the correct padding-top on the
    // layout page, so we re-use the padding set there to determine at what height our
    // element should be sticky
    const pageLayout = document.querySelector('.layout-page');
    const pageLayoutTopOffset = pageLayout
      ? parseFloat(window.getComputedStyle(pageLayout).getPropertyValue('padding-top') || 0)
      : 0;

    stickyMonitor(document.querySelector('.js-diff-files-changed'), pageLayoutTopOffset, false);
  }

  const el = document.querySelector('.js-diff-stats-dropdown');

  if (!el) {
    return false;
  }

  const { changed, added, deleted, files } = el.dataset;

  return new Vue({
    el,
    render: (createElement) =>
      createElement(DiffStatsDropdown, {
        props: {
          changed: parseInt(changed, 10),
          added: parseInt(added, 10),
          deleted: parseInt(deleted, 10),
          files: JSON.parse(files),
        },
      }),
  });
};
