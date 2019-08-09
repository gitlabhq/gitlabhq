import { comment, login, mrForm } from '../components';
import { localStorage, COMMENT_BOX, LOGIN, MR_ID, STORAGE_MR_ID, STORAGE_TOKEN } from '../shared';

const state = {
  browser: '',
  usingGracefulStorage: '',
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
  /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
  const aKeys = ['MSIE', 'Edge', 'Firefox', 'Safari', 'Chrome', 'Opera'];
  let nIdx = aKeys.length - 1;

  for (nIdx; nIdx > -1 && sUsrAg.indexOf(aKeys[nIdx]) === -1; nIdx -= 1);
  return aKeys[nIdx];
};

const nextView = (appState, form = 'none') => {
  const formsList = {
    [COMMENT_BOX]: currentState => (currentState.token ? mrForm : login),
    [LOGIN]: currentState => (currentState.mergeRequestId ? comment(currentState) : mrForm),
    [MR_ID]: currentState => (currentState.token ? comment(currentState) : login),
    none: currentState => {
      if (!currentState.token) {
        return login;
      }

      if (currentState.token && !currentState.mergeRequestId) {
        return mrForm;
      }

      return comment(currentState);
    },
  };

  return formsList[form](appState);
};

const initializeState = (wind, doc) => {
  const {
    innerWidth,
    innerHeight,
    navigator: { platform, userAgent },
  } = wind;

  const browser = getBrowserId(userAgent);

  const scriptEl = doc.getElementById('review-app-toolbar-script');
  const { projectId, mergeRequestId, mrUrl, projectPath } = scriptEl.dataset;

  // This mutates our default state object above. It's weird but it makes the linter happy.
  Object.assign(state, {
    browser,
    innerWidth,
    innerHeight,
    mergeRequestId,
    mrUrl,
    platform,
    projectId,
    projectPath,
    userAgent,
  });

  return state;
};

const getInitialView = () => {
  const token = localStorage.getItem(STORAGE_TOKEN);
  const mrId = localStorage.getItem(STORAGE_MR_ID);

  if (token) {
    state.token = token;
  }

  if (mrId) {
    state.mergeRequestId = mrId;
  }

  return nextView(state);
};

const setUsingGracefulStorageFlag = flag => {
  state.usingGracefulStorage = !flag;
};

export { initializeState, getInitialView, nextView, setUsingGracefulStorageFlag, state };
