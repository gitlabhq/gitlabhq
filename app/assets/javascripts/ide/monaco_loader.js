import monacoContext from 'monaco-editor/dev/vs/loader';

monacoContext.require.config({
  paths: {
    vs: `${__webpack_public_path__}monaco-editor/vs`, // eslint-disable-line camelcase
  },
});

// ignore CDN config and use local assets path for service worker which cannot be cross-domain
const relativeRootPath = (gon && gon.relative_url_root) || '';
const monacoPath = `${relativeRootPath}/assets/webpack/monaco-editor/vs`;
window.MonacoEnvironment = { getWorkerUrl: () => `${monacoPath}/base/worker/workerMain.js` };

// eslint-disable-next-line no-underscore-dangle
window.__monaco_context__ = monacoContext;
export default monacoContext.require;
