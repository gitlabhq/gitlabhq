import { waitForText } from 'helpers/wait_for_text';
import waitForPromises from 'helpers/wait_for_promises';
import { useOverclockTimers } from 'test_helpers/utils/overclock_timers';
import { createCommitId } from 'test_helpers/factories/commit_id';
import * as ideHelper from './helpers/ide_helper';

describe('WebIDE', () => {
  useOverclockTimers();

  let vm;
  let container;

  beforeEach(() => {
    setFixtures('<div class="webide-container"></div>');
    container = document.querySelector('.webide-container');
  });

  afterEach(() => {
    vm.$destroy();
    vm = null;
  });

  it('user commits changes', async () => {
    vm = ideHelper.createIdeComponent(container);

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
    vm = ideHelper.createIdeComponent(container);

    await ideHelper.createFile('+test', 'Hello world!');
    await ideHelper.openFile('+test');

    // Wait for monaco things
    await waitForPromises();

    // Assert that +test is the only open tab
    const tabs = Array.from(document.querySelectorAll('.multi-file-tab'));
    expect(tabs.map(x => x.textContent.trim())).toEqual(['+test']);
  });
});
