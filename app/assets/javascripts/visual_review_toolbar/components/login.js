import { nextView } from '../store';
import { localStorage, LOGIN, TOKEN_BOX } from '../shared';
import { clearNote, postError } from './note';
import { rememberBox, submitButton } from './form_elements';
import { selectRemember, selectToken } from './utils';
import { addForm } from './wrapper';

const labelText = `
  Enter your <a class="gitlab-link" href="https://docs.gitlab.com/ee/user/profile/personal_access_tokens.html">personal access token</a>
`;

const login = `
    <div>
      <label for="${TOKEN_BOX}" class="gitlab-label">${labelText}</label>
      <input class="gitlab-input" type="password" id="${TOKEN_BOX}" name="${TOKEN_BOX}" autocomplete="current-password" aria-required="true">
    </div>
    ${rememberBox()}
    ${submitButton(LOGIN)}
`;

const storeToken = (token, state) => {
  const rememberMe = selectRemember().checked;

  if (rememberMe) {
    localStorage.setItem('token', token);
  }

  state.token = token;
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
  addForm(nextView(state, LOGIN));
};

export { authorizeUser, login, storeToken };
