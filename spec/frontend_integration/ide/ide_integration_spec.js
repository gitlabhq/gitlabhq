import { TEST_HOST } from 'helpers/test_constants';
import { waitForText } from 'helpers/wait_for_text';
import waitForPromises from 'helpers/wait_for_promises';
import { useOverclockTimers } from 'test_helpers/utils/overclock_timers';
import { createCommitId } from 'test_helpers/factories/commit_id';
import { initIde } from '~/ide';
import extendStore from '~/ide/stores/extend';
import * as ideHelper from './ide_helper';

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

  it('user commits changes', async () => {
    createComponent();

    await ideHelper.createFile('foo/bar/test.txt', 'Lorem ipsum dolar sit');
    await ideHelper.deleteFile('foo/bar/.gitkeep');
    await ideHelper.commit();

    const commitId = createCommitId(1);
    const commitShortId = commitId.slice(0, 8);

    await waitForText('All changes are committed');
    await waitForText(commitShortId);

    expect(mockServer.db.branches.findBy({ name: 'master' }).commit).toMatchObject({
      short_id: commitShortId,
      id: commitId,
      message: 'Update foo/bar/test.txt\nDeleted foo/bar/.gitkeep',
      __actions: [
        {
          action: 'create',
          content: 'Lorem ipsum dolar sit\n',
          encoding: 'text',
          file_path: 'foo/bar/test.txt',
          last_commit_id: '',
        },
        {
          action: 'delete',
          encoding: 'text',
          file_path: 'foo/bar/.gitkeep',
        },
      ],
    });
  });

  it('user adds file that starts with +', async () => {
    createComponent();

    await ideHelper.createFile('+test', 'Hello world!');
    await ideHelper.openFile('+test');

    // Wait for monaco things
    await waitForPromises();

    // Assert that +test is the only open tab
    const tabs = Array.from(document.querySelectorAll('.multi-file-tab'));
    expect(tabs.map(x => x.textContent.trim())).toEqual(['+test']);
  });
});
