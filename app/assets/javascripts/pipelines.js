import LinkedTabs from './lib/utils/bootstrap_linked_tabs';
import { setCiStatusFavicon } from './lib/utils/common_utils';

export default class Pipelines {
  constructor(options = {}) {
    if (options.initTabs && options.tabsOptions) {
      // eslint-disable-next-line no-new
      new LinkedTabs(options.tabsOptions);
    }

    if (options.pipelineStatusUrl) {
      setCiStatusFavicon(options.pipelineStatusUrl);
    }
  }
}
