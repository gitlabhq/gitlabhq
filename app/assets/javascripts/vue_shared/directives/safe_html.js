import { sanitize } from '~/lib/dompurify';

// Mitigate against future dompurify mXSS bypasses by
// avoiding additional serialize/parse round trip.
// See https://gitlab.com/gitlab-org/gitlab-ui/-/merge_requests/1782
// and https://gitlab.com/gitlab-org/gitlab-ui/-/merge_requests/2127
// for more details.
const DEFAULT_CONFIG = {
  RETURN_DOM_FRAGMENT: true,
};

const transform = (el, binding) => {
  if (binding.oldValue !== binding.value) {
    const config = { ...DEFAULT_CONFIG, ...binding.arg };

    el.textContent = '';

    el.appendChild(sanitize(binding.value, config));
  }
};

const clear = (el) => {
  el.textContent = '';
};

export default {
  bind: transform,
  update: transform,
  unbind: clear,
};
