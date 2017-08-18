import LinkedTabs from './lib/utils/bootstrap_linked_tabs';

export default class Pipelines {
  constructor(options = {}) {
    if (options.initTabs && options.tabsOptions) {
      // eslint-disable-next-line no-new
      new LinkedTabs(options.tabsOptions);
    }

    if (options.pipelineStatusUrl) {
      gl.utils.setCiStatusFavicon(options.pipelineStatusUrl);
    }
  }
}
