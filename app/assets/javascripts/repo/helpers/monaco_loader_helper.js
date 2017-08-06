/* global monaco */
import RepoEditor from '../components/repo_editor.vue';
import Store from '../stores/repo_store';
import monacoLoader from '../monaco_loader';

function repoEditorLoader() {
  Store.monacoLoading = true;
  return new Promise((resolve) => {
    monacoLoader(['vs/editor/editor.main'], () => {
      Store.monaco = monaco;
      Store.monacoLoading = false;
      resolve(RepoEditor);
    });
  });
}

const MonacoLoaderHelper = {
  repoEditorLoader,
};

export default MonacoLoaderHelper;
