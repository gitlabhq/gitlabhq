import { TEST_HOST } from 'helpers/test_constants';
import extendStore from '~/ide/stores/extend';
import { initIde } from '~/ide';
import Editor from '~/ide/lib/editor';
import { IDE_DATASET } from './mock_data';

export default (container, { isRepoEmpty = false, path = '' } = {}) => {
  global.jsdom.reconfigure({
    url: `${TEST_HOST}/-/ide/project/gitlab-test/lorem-ipsum${
      isRepoEmpty ? '-empty' : ''
    }/tree/master/-/${path}`,
  });

  const el = document.createElement('div');
  Object.assign(el.dataset, IDE_DATASET);
  container.appendChild(el);
  const vm = initIde(el, { extendStore });

  // We need to dispose of editor Singleton things or tests will bump into eachother
  vm.$on('destroy', () => {
    if (Editor.editorInstance) {
      Editor.editorInstance.modelManager.dispose();
      Editor.editorInstance.dispose();
      Editor.editorInstance = null;
    }
  });

  return vm;
};
