/* global monaco */
import RepoEditor from '../components/repo_editor.vue';
import RepoStore from '../stores/repo_store';
import monacoLoader from '../monaco_loader';

function repoEditorLoader() {
  RepoStore.monacoLoading = true;
  return new Promise((resolve) => {
    monacoLoader(['vs/editor/editor.main'], () => {
      RepoStore.monaco = monaco;
      RepoStore.monacoLoading = false;
      resolve(RepoEditor);
    });
  });
}

const MonacoLoaderHelper = {
  repoEditorLoader,
};

export default MonacoLoaderHelper;
