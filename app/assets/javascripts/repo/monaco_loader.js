import monacoContext from 'monaco-editor/dev/vs/loader';

monacoContext.require.config({
  paths: {
    vs: `${__webpack_public_path__}monaco-editor/vs`, // eslint-disable-line camelcase
  },
});

// eslint-disable-next-line no-underscore-dangle
window.__monaco_context__ = monacoContext;
export default monacoContext.require;
