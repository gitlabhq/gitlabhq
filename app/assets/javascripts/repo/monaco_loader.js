/* eslint-disable no-underscore-dangle, camelcase */
/* global __webpack_public_path__ */

import monacoContext from 'monaco-editor/dev/vs/loader';

function monacoLoader() {
  monacoContext.require.config({
    paths: {
      vs: `${__webpack_public_path__}monaco-editor/vs`,
    },
  });

  window.__monaco_context__ = monacoContext;

  return monacoContext.require;
}

export default monacoLoader;
