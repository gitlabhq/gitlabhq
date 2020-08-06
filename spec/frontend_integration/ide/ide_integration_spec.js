/**
 * WARNING: WIP
 *
 * Please do not copy from this spec or use it as an example for anything.
 *
 * This is in place to iteratively set up the frontend integration testing environment
 * and will be improved upon in a later iteration.
 *
 * See https://gitlab.com/gitlab-org/gitlab/-/issues/208800 for more information.
 */
import { initIde } from '~/ide';
import extendStore from '~/ide/stores/extend';
import { TEST_HOST } from 'helpers/test_constants';
import { useOverclockTimers } from 'test_helpers/utils/overclock_timers';

const TEST_DATASET = {
  emptyStateSvgPath: '/test/empty_state.svg',
  noChangesStateSvgPath: '/test/no_changes_state.svg',
  committedStateSvgPath: '/test/committed_state.svg',
  pipelinesEmptyStateSvgPath: '/test/pipelines_empty_state.svg',
  promotionSvgPath: '/test/promotion.svg',
  ciHelpPagePath: '/test/ci_help_page',
  webIDEHelpPagePath: '/test/web_ide_help_page',
  clientsidePreviewEnabled: 'true',
  renderWhitespaceInCode: 'false',
  codesandboxBundlerUrl: 'test/codesandbox_bundler',
};

describe('WebIDE', () => {
  useOverclockTimers();

  let vm;
  let root;

  beforeEach(() => {
    root = document.createElement('div');
    document.body.appendChild(root);

    global.jsdom.reconfigure({
      url: `${TEST_HOST}/-/ide/project/gitlab-test/lorem-ipsum`,
    });
  });

  afterEach(() => {
    vm.$destroy();
    vm = null;
    root.remove();
  });

  const createComponent = () => {
    const el = document.createElement('div');
    Object.assign(el.dataset, TEST_DATASET);
    root.appendChild(el);
    vm = initIde(el, { extendStore });
  };

  it('runs', () => {
    createComponent();

    expect(root).toMatchSnapshot();
  });
});
