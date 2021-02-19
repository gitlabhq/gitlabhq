import Api from '~/api';
import { historyPushState } from '~/lib/utils/common_utils';
import { mergeUrlParams } from '~/lib/utils/url_utility';

const COHORTS_PANE = 'cohorts';
const COHORTS_PANE_TAB_CLICK_EVENT = 'i_analytics_cohorts';

const tabClickHandler = (e) => {
  const { hash } = e.currentTarget;

  let tab = null;

  if (hash === `#${COHORTS_PANE}`) {
    tab = COHORTS_PANE;
    Api.trackRedisHllUserEvent(COHORTS_PANE_TAB_CLICK_EVENT);
  }

  const newUrl = mergeUrlParams({ tab }, window.location.href);
  historyPushState(newUrl);
};

const initTabs = () => {
  const tabLinks = document.querySelectorAll('.js-users-tab-item a');

  if (tabLinks.length) {
    tabLinks.forEach((tabLink) => {
      tabLink.addEventListener('click', (e) => tabClickHandler(e));
    });
  }
};

export default initTabs;
