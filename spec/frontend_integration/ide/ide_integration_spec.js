import { waitForText } from 'helpers/wait_for_text';
import waitForPromises from 'helpers/wait_for_promises';
import { useOverclockTimers } from 'test_helpers/utils/overclock_timers';
import { createCommitId } from 'test_helpers/factories/commit_id';
import * as ideHelper from './helpers/ide_helper';
import startWebIDE from './helpers/start';

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
    vm = startWebIDE(container);

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
    vm = startWebIDE(container);

    await ideHelper.createFile('+test', 'Hello world!');
    await ideHelper.openFile('+test');

    // Wait for monaco things
    await waitForPromises();

    // Assert that +test is the only open tab
    const tabs = Array.from(document.querySelectorAll('.multi-file-tab'));
    expect(tabs.map(x => x.textContent.trim())).toEqual(['+test']);
  });

  describe('editor info', () => {
    let statusBar;
    let editor;

    const waitForEditor = async () => {
      editor = await ideHelper.waitForMonacoEditor();
    };

    const changeEditorPosition = async (lineNumber, column) => {
      editor.setPosition({ lineNumber, column });

      await vm.$nextTick();
    };

    beforeEach(async () => {
      vm = startWebIDE(container);

      await ideHelper.openFile('README.md');
      editor = await ideHelper.waitForMonacoEditor();

      statusBar = ideHelper.getStatusBar();
    });

    it('shows line position and type', () => {
      expect(statusBar).toHaveText('1:1');
      expect(statusBar).toHaveText('markdown');
    });

    it('persists viewer', async () => {
      const markdownPreview = 'test preview_markdown result';
      mockServer.post('/:namespace/:project/preview_markdown', () => ({
        body: markdownPreview,
      }));

      await ideHelper.openFile('README.md');
      ideHelper.clickPreviewMarkdown();

      const el = await waitForText(markdownPreview);
      expect(el).toHaveText(markdownPreview);

      // Need to wait for monaco editor to load so it doesn't through errors on dispose
      await ideHelper.openFile('.gitignore');
      await ideHelper.waitForMonacoEditor();
      await ideHelper.openFile('README.md');
      await ideHelper.waitForMonacoEditor();

      expect(el).toHaveText(markdownPreview);
    });

    describe('when editor position changes', () => {
      beforeEach(async () => {
        await changeEditorPosition(4, 10);
      });

      it('shows new line position', () => {
        expect(statusBar).not.toHaveText('1:1');
        expect(statusBar).toHaveText('4:10');
      });

      it('updates after rename', async () => {
        await ideHelper.renameFile('README.md', 'READMEZ.txt');
        await waitForEditor();

        expect(statusBar).toHaveText('1:1');
        expect(statusBar).toHaveText('plaintext');
      });

      it('persists position after opening then rename', async () => {
        await ideHelper.openFile('files/js/application.js');
        await waitForEditor();
        await ideHelper.renameFile('README.md', 'READING_RAINBOW.md');
        await ideHelper.openFile('READING_RAINBOW.md');
        await waitForEditor();

        expect(statusBar).toHaveText('4:10');
        expect(statusBar).toHaveText('markdown');
      });

      it('persists position after closing', async () => {
        await ideHelper.closeFile('README.md');
        await ideHelper.openFile('README.md');
        await waitForEditor();

        expect(statusBar).toHaveText('4:10');
        expect(statusBar).toHaveText('markdown');
      });
    });
  });
});
