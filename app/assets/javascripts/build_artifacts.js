import { hide, initTooltips, show } from '~/tooltips';
import { parseBoolean } from './lib/utils/common_utils';
import { visitUrl } from './lib/utils/url_utility';

export default class BuildArtifacts {
  constructor() {
    this.disablePropagation();
    this.setupEntryClick();
    this.setupTooltips();
  }

  // eslint-disable-next-line class-methods-use-this
  disablePropagation() {
    document.querySelectorAll('.top-block').forEach((topBlock) => {
      topBlock.addEventListener('click', (e) => {
        if (e.target.closest('.download')) {
          e.stopPropagation();
        }
      });
    });
  }

  // eslint-disable-next-line class-methods-use-this
  setupEntryClick() {
    document.querySelectorAll('.tree-holder').forEach((treeHolder) => {
      treeHolder.addEventListener('click', (e) => {
        const row = e.target.closest('tr[data-link]');
        if (!row) return;

        // Let real anchors behave normally; only synthesize navigation
        // when the click wasn't on a link inside the row.
        if (e.target.closest('a')) return;

        visitUrl(row.dataset.link, parseBoolean(row.dataset.externalLink));
      });
    });
  }

  // eslint-disable-next-line class-methods-use-this
  setupTooltips() {
    initTooltips({
      placement: 'bottom',
      // Stop the tooltip from hiding when we stop hovering the element directly
      // We handle all the showing/hiding below
      trigger: 'manual',
    });

    // We want the tooltip to show if you hover anywhere on the row
    // But be placed below and in the middle of the file name
    document.querySelectorAll('.js-artifact-tree-row').forEach((row) => {
      row.addEventListener('mouseenter', () => {
        const el = row.querySelector('.js-artifact-tree-tooltip');
        show(el);
      });
      row.addEventListener('mouseleave', () => {
        const el = row.querySelector('.js-artifact-tree-tooltip');
        hide(el);
      });
    });
  }
}
