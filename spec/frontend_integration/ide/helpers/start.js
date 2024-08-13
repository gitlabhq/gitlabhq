import { editor as monacoEditor } from 'monaco-editor';
import setWindowLocation from 'helpers/set_window_location_helper';
import { TEST_HOST } from 'helpers/test_constants';
import { initLegacyWebIDE } from '~/ide/init_legacy_web_ide';
import extendStore from '~/ide/stores/extend';
import { getProject, getEmptyProject } from 'jest/../frontend_integration/test_helpers/fixtures';
import { IDE_DATASET } from './mock_data';

export default (container, { isRepoEmpty = false, path = '', mrId = '' } = {}) => {
  const projectName = isRepoEmpty ? 'lorem-ipsum-empty' : 'lorem-ipsum';
  const pathSuffix = mrId ? `merge_requests/${mrId}` : `tree/master/-/${path}`;
  const project = isRepoEmpty ? getEmptyProject() : getProject();

  setWindowLocation(`${TEST_HOST}/-/ide/project/gitlab-test/${projectName}/${pathSuffix}`);

  const el = document.createElement('div');
  Object.assign(el.dataset, IDE_DATASET, { project: JSON.stringify(project) });
  container.appendChild(el);
  const vm = initLegacyWebIDE(el, { extendStore });

  // We need to dispose of editor Singleton things or tests will bump into eachother
  vm.$on('destroy', () => monacoEditor.getModels().forEach((model) => model.dispose()));

  return vm;
};
