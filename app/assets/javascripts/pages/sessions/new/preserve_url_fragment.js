import { mergeUrlParams, removeParams, setUrlFragment } from '~/lib/utils/url_utility';

/**
 * Append the fragment to all non-OAuth login form actions so it is preserved
 * when the user is eventually redirected back to the originally requested URL.
 *
 * @param fragment {string} - url fragment to be preserved
 */
export function appendUrlFragment(fragment = document.location.hash) {
  if (!fragment) {
    return;
  }

  const normalFragment = fragment.replace(/^#/, '');
  const forms = document.querySelectorAll('.js-non-oauth-login form');
  forms.forEach((form) => {
    const actionWithFragment = setUrlFragment(form.getAttribute('action'), `#${normalFragment}`);
    form.setAttribute('action', actionWithFragment);
  });
}

/**
 * Append a redirect_fragment query param to all OAuth login form actions. The
 * redirect_fragment query param will be available in the omniauth callback upon
 * successful authentication.
 *
 * @param {string} fragment - url fragment to be preserved
 */
export function appendRedirectQuery(fragment = document.location.hash) {
  if (!fragment) {
    return;
  }

  const normalFragment = fragment.replace(/^#/, '');
  const oauthForms = document.querySelectorAll('.js-oauth-login form');
  oauthForms.forEach((oauthForm) => {
    const newHref = mergeUrlParams(
      { redirect_fragment: normalFragment },
      oauthForm.getAttribute('action'),
    );
    oauthForm.setAttribute('action', newHref);
  });
}

/**
 * OAuth login buttons have a separate "remember me" checkbox.
 *
 * Toggling this checkbox adds/removes a `remember_me` parameter to the
 * login form actions, which is passed on to the omniauth callback.
 */
export function toggleRememberMeQuery() {
  const oauthForms = document.querySelectorAll('.js-oauth-login form');
  const checkbox = document.querySelector('#js-remember-me-omniauth');

  if (oauthForms.length === 0 || !checkbox) {
    return;
  }

  checkbox.addEventListener('change', ({ currentTarget }) => {
    oauthForms.forEach((oauthForm) => {
      const href = oauthForm.getAttribute('action');
      let newHref;
      if (currentTarget.checked) {
        newHref = mergeUrlParams({ remember_me: '1' }, href);
      } else {
        newHref = removeParams(['remember_me'], href);
      }

      oauthForm.setAttribute('action', newHref);
    });
  });
}
