/* global monaco */
import RepoEditor from '../components/repo_editor.vue';
import Store from '../stores/repo_store';
import Helper from '../helpers/repo_helper';
import monacoLoader from '../monaco_loader';

function repoEditorLoader() {
  Store.monacoLoading = true;
  return new Promise((resolve, reject) => {
    monacoLoader(['vs/editor/editor.main'], () => {
      Helper.monaco = monaco;
      Store.monacoLoading = false;
      resolve(RepoEditor);
    }, () => {
      Store.monacoLoading = false;
      reject();
    });
  });
}

const MonacoLoaderHelper = {
  repoEditorLoader,
};

export default MonacoLoaderHelper;
