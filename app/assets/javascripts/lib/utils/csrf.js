/*
This module provides easy access to the CSRF token and caches
it for re-use. It also exposes some values commonly used in relation
to the CSRF token (header key and headers object).

If you need to refresh the csrfToken for some reason, just call `init` and
then use the accessors as you would normally.

If you need to compose a headers object, use the spread operator:

```
  headers: {
    ...csrf.headers,
    someOtherHeader: '12345',
  }
```
 */

const csrf = {
  init() {
    const tokenEl = document.querySelector('meta[name=csrf-token]');

    if (tokenEl !== null) {
      this.csrfToken = tokenEl.getAttribute('content');
    } else {
      this.csrfToken = null;
    }
  },

  get token() {
    return this.csrfToken;
  },

  get headerKey() {
    return 'X-CSRF-Token';
  },

  get headers() {
    if (this.csrfToken !== null) {
      return {
        [this.headerKey]: this.token,
      };
    }
    return {};
  },
};

csrf.init();

// use our cached token for any $.rails-generated AJAX requests
if ($.rails) {
  $.rails.csrfToken = () => csrf.token;
}

export default csrf;

