import { TEST_HOST } from 'helpers/test_constants';
import extendStore from '~/ide/stores/extend';
import { IDE_DATASET } from './mock_data';
import { initIde } from '~/ide';

export default (container, { isRepoEmpty = false, path = '' } = {}) => {
  global.jsdom.reconfigure({
    url: `${TEST_HOST}/-/ide/project/gitlab-test/lorem-ipsum${
      isRepoEmpty ? '-empty' : ''
    }/tree/master/-/${path}`,
  });

  const el = document.createElement('div');
  Object.assign(el.dataset, IDE_DATASET);
  container.appendChild(el);
  return initIde(el, { extendStore });
};
