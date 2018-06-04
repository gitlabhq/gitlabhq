import { setUrlFragment, setUrlParam } from '../../../lib/utils/common_utils';

/**
 * Ensure the given URL fragment is preserved by appending it to sign-in/sign-up form actions and
 * OAuth/SAML login links.
 *
 * @param fragment {string} - url fragment to be preserved
 */
export default function preserveUrlFragment(fragment) {
  if (fragment && fragment !== '') {
    const normalFragment = fragment.replace(/^#/, '');

    // Append the fragment to all sign-in/sign-up form actions so it is preserved when the user is
    // eventually redirected back to the originally requested URL.
    const forms = document.querySelectorAll('#signin-container form');
    Array.prototype.forEach.call(forms, (form) => {
      const actionWithFragment = setUrlFragment(form.getAttribute('action'), `#${normalFragment}`);
      form.setAttribute('action', actionWithFragment);
    });

    // Append a redirect_fragment query param to all oauth provider links. The redirect_fragment
    // query param will be available in the omniauth callback upon successful authentication
    const anchors = document.querySelectorAll('#signin-container a.oauth-login');
    Array.prototype.forEach.call(anchors, (anchor) => {
      const newHref = setUrlParam(anchor.getAttribute('href'), 'redirect_fragment', normalFragment);
      anchor.setAttribute('href', newHref);
    });
  }
}
