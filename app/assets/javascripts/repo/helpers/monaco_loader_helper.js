/* global monaco */
import RepoEditor from '../components/repo_editor.vue';
import Helper from '../helpers/repo_helper';
import monacoLoader from '../monaco_loader';

function repoEditorLoader() {
  return new Promise((resolve, reject) => {
    monacoLoader(['vs/editor/editor.main'], () => {
      Helper.monaco = monaco;
      resolve(RepoEditor);
    }, () => {
      reject();
    });
  });
}

const MonacoLoaderHelper = {
  repoEditorLoader,
};

export default MonacoLoaderHelper;
