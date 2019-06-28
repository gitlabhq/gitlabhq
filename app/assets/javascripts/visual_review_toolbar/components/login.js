import { LOGIN, REMEMBER_TOKEN, TOKEN_BOX } from './constants';
import { clearNote, postError } from './note';
import { buttonClearStyles, selectRemember, selectToken } from './utils';
import { addCommentForm } from './wrapper';

const login = `
  <div>
    <label for="${TOKEN_BOX}" class="gitlab-label">Enter your <a class="gitlab-link" href="https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html">personal access token</a></label>
    <input class="gitlab-input" type="password" id="${TOKEN_BOX}" name="${TOKEN_BOX}" aria-required="true" autocomplete="current-password">
  </div>
  <div class="gitlab-checkbox-wrapper">
    <input type="checkbox" id="${REMEMBER_TOKEN}" name="${REMEMBER_TOKEN}" value="remember">
    <label for="${REMEMBER_TOKEN}" class="gitlab-checkbox-label">Remember me</label>
  </div>
  <div class="gitlab-button-wrapper">
    <button class="gitlab-button-wide gitlab-button gitlab-button-success" style="${buttonClearStyles}" type="button" id="${LOGIN}"> Submit </button>
  </div>
`;

const storeToken = (token, state) => {
  const { localStorage } = window;
  const rememberMe = selectRemember().checked;

  // All the browsers we support have localStorage, so let's silently fail
  // and go on with the rest of the functionality.
  try {
    if (rememberMe) {
      localStorage.setItem('token', token);
    }
  } finally {
    state.token = token;
  }
};

const authorizeUser = state => {
  // Clear any old errors
  clearNote(TOKEN_BOX);

  const token = selectToken().value;

  if (!token) {
    /* eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings */
    postError('Please enter your token.', TOKEN_BOX);
    return;
  }

  storeToken(token, state);
  addCommentForm();
};

export { authorizeUser, login };
