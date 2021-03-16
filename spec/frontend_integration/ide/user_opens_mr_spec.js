import { basename } from 'path';
import { getMergeRequests, getMergeRequestWithChanges } from 'test_helpers/fixtures';
import { useOverclockTimers } from 'test_helpers/utils/overclock_timers';
import * as ideHelper from './helpers/ide_helper';
import startWebIDE from './helpers/start';

const getRelevantChanges = () =>
  getMergeRequestWithChanges().changes.filter((x) => !x.deleted_file);

describe('IDE: User opens Merge Request', () => {
  useOverclockTimers();

  let vm;
  let container;
  let changes;

  beforeEach(async () => {
    const [{ iid: mrId }] = getMergeRequests();

    changes = getRelevantChanges();

    setFixtures('<div class="webide-container"></div>');
    container = document.querySelector('.webide-container');

    vm = startWebIDE(container, { mrId });

    const editor = await ideHelper.waitForMonacoEditor();
    await ideHelper.waitForEditorModelChange(editor);
  });

  afterEach(() => {
    vm.$destroy();
    vm = null;
  });

  const findAllTabs = () => Array.from(document.querySelectorAll('.multi-file-tab'));
  const findAllTabsData = () =>
    findAllTabs().map((el) => ({
      title: el.getAttribute('title'),
      text: el.textContent.trim(),
    }));

  it('shows first change as active in file tree', async () => {
    const firstPath = changes[0].new_path;
    const row = await ideHelper.findAndTraverseToPath(firstPath);

    expect(row).toHaveClass('is-open');
    expect(row).toHaveClass('is-active');
  });

  it('opens other changes', () => {
    // We only show first 10 changes
    const expectedTabs = changes.slice(0, 10).map((x) => ({
      title: `${ideHelper.getBaseRoute()}/-/${x.new_path}/`,
      text: basename(x.new_path),
    }));

    expect(findAllTabsData()).toEqual(expectedTabs);
  });
});
