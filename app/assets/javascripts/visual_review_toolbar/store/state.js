import { comment, login, collapseButton } from '../components';

const state = {
  browser: '',
  href: '',
  innerWidth: '',
  innerHeight: '',
  mergeRequestId: '',
  mrUrl: '',
  platform: '',
  projectId: '',
  userAgent: '',
  token: '',
};

// adapted from https://developer.mozilla.org/en-US/docs/Web/API/Window/navigator#Example_2_Browser_detect_and_return_an_index
const getBrowserId = sUsrAg => {
  const aKeys = ['MSIE', 'Edge', 'Firefox', 'Safari', 'Chrome', 'Opera'];
  let nIdx = aKeys.length - 1;

  for (nIdx; nIdx > -1 && sUsrAg.indexOf(aKeys[nIdx]) === -1; nIdx -= 1);
  return aKeys[nIdx];
};

const initializeState = (wind, doc) => {
  const {
    innerWidth,
    innerHeight,
    location: { href },
    navigator: { platform, userAgent },
  } = wind;

  const browser = getBrowserId(userAgent);

  const scriptEl = doc.getElementById('review-app-toolbar-script');
  const { projectId, mergeRequestId, mrUrl } = scriptEl.dataset;

  // This mutates our default state object above. It's weird but it makes the linter happy.
  Object.assign(state, {
    browser,
    href,
    innerWidth,
    innerHeight,
    mergeRequestId,
    mrUrl,
    platform,
    projectId,
    userAgent,
  });
};

function getInitialView({ localStorage }) {
  const loginView = {
    content: login,
    toggleButton: collapseButton,
  };

  const commentView = {
    content: comment,
    toggleButton: collapseButton,
  };

  try {
    const token = localStorage.getItem('token');

    if (token) {
      state.token = token;
      return commentView;
    }
    return loginView;
  } catch (err) {
    return loginView;
  }
}

export { initializeState, getInitialView, state };
