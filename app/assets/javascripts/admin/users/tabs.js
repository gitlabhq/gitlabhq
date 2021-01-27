import { historyPushState } from '~/lib/utils/common_utils';
import { mergeUrlParams } from '~/lib/utils/url_utility';

const COHORTS_PANE = 'cohorts';

const tabClickHandler = (e) => {
  const { hash } = e.currentTarget;
  const tab = hash === `#${COHORTS_PANE}` ? COHORTS_PANE : null;
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
