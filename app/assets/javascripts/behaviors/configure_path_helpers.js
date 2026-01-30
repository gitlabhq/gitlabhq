import { configure } from '~/lib/utils/path_helpers/core';

configure({
  // We need to configure relative_url_root globally here for `path_helpers/*.js`
  // eslint-disable-next-line @gitlab/no-hardcoded-urls
  default_url_options: { script_name: window.gon?.relative_url_root || '' },
});
