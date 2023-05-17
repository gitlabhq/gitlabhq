import $ from 'jquery';
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
    $('.top-block').on('click', '.download', (e) => {
      e.stopPropagation();
    });
    return $('.tree-holder').on('click', 'tr[data-link] a', (e) => {
      e.stopImmediatePropagation();
    });
  }

  // eslint-disable-next-line class-methods-use-this
  setupEntryClick() {
    // eslint-disable-next-line func-names
    return $('.tree-holder').on('click', 'tr[data-link]', function () {
      visitUrl(this.dataset.link, parseBoolean(this.dataset.externalLink));
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
    $('.js-artifact-tree-row')
      .on('mouseenter', (e) => {
        const $el = $(e.currentTarget).find('.js-artifact-tree-tooltip');

        show($el);
      })
      .on('mouseleave', (e) => {
        const $el = $(e.currentTarget).find('.js-artifact-tree-tooltip');

        hide($el);
      });
  }
}
