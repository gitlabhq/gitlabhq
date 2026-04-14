import { nextTick } from 'vue';
import { setActivePinia } from 'pinia';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import { createNoPreviewDiscussionsAdapter } from '~/rapid_diffs/adapters/no_preview_discussions';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import { useDiscussions } from '~/notes/store/discussions';
import { pinia } from '~/pinia/instance';
import { createAlert, VARIANT_INFO } from '~/alert';

jest.mock('~/alert');

describe('createNoPreviewDiscussionsAdapter', () => {
  const oldPath = 'old';
  const newPath = 'new';

  const getDiffFile = () => document.querySelector('diff-file');

  let store;
  let adapter;

  if (!customElements.get('diff-file')) {
    customElements.define('diff-file', DiffFile);
  }

  beforeEach(() => {
    setActivePinia(pinia);
    store = useDiffDiscussions();
    adapter = createNoPreviewDiscussionsAdapter(store);
  });

  afterEach(() => {
    useDiscussions().discussions = [];
    store.discussionForms = [];
    resetHTMLFixture();
    createAlert.mockClear();
  });

  const mountAdapter = () => {
    const fileData = { viewer: 'no_preview', old_path: oldPath, new_path: newPath };
    setHTMLFixture(`
      <diff-file data-file-data='${JSON.stringify(fileData)}'>
        <div>
          <div class="flash-container"></div>
        </div>
      </diff-file>
    `);
    getDiffFile().mount({
      adapterConfig: { no_preview: [adapter] },
      appData: {},
      unobserve: jest.fn(),
    });
  };

  const lineDiscussion = (id, { oldLine = 1, newLine = null } = {}) => ({
    id,
    diff_discussion: true,
    position: { old_path: oldPath, new_path: newPath, old_line: oldLine, new_line: newLine },
  });

  it('does not show alert when there are no discussions', () => {
    mountAdapter();
    expect(createAlert).not.toHaveBeenCalled();
  });

  it('shows an info alert for a single line discussion', async () => {
    mountAdapter();
    useDiscussions().discussions = [lineDiscussion('disc-1')];
    await nextTick();
    expect(createAlert).toHaveBeenCalledWith(
      expect.objectContaining({
        variant: VARIANT_INFO,
        message: '1 thread hidden.',
      }),
    );
  });

  it('uses plural message for multiple line discussions', async () => {
    mountAdapter();
    useDiscussions().discussions = [
      lineDiscussion('disc-1'),
      lineDiscussion('disc-2', { oldLine: 2 }),
    ];
    await nextTick();
    expect(createAlert).toHaveBeenCalledWith(
      expect.objectContaining({
        message: '2 threads hidden.',
      }),
    );
  });

  it('does not show alert for file-level discussions', async () => {
    mountAdapter();
    useDiscussions().discussions = [
      {
        id: 'file-disc',
        diff_discussion: true,
        position: {
          old_path: oldPath,
          new_path: newPath,
          position_type: 'file',
          old_line: null,
          new_line: null,
        },
      },
    ];
    await nextTick();
    expect(createAlert).not.toHaveBeenCalled();
  });

  it('does not show alert for discussions on different paths', async () => {
    mountAdapter();
    useDiscussions().discussions = [
      {
        id: 'other-disc',
        diff_discussion: true,
        position: { old_path: 'other', new_path: 'other', old_line: 1, new_line: null },
      },
    ];
    await nextTick();
    expect(createAlert).not.toHaveBeenCalled();
  });

  it('dismisses the alert when all discussions are removed', async () => {
    const mockDismiss = jest.fn();
    createAlert.mockReturnValue({ dismiss: mockDismiss });
    mountAdapter();
    useDiscussions().discussions = [lineDiscussion('disc-1')];
    await nextTick();
    useDiscussions().discussions = [];
    await nextTick();
    expect(mockDismiss).toHaveBeenCalled();
    expect(createAlert).toHaveBeenCalledTimes(1);
  });

  it('dismisses old alert and creates a new one when the discussion count changes', async () => {
    const mockDismiss = jest.fn();
    createAlert.mockReturnValue({ dismiss: mockDismiss });
    mountAdapter();
    useDiscussions().discussions = [lineDiscussion('disc-1')];
    await nextTick();
    useDiscussions().discussions = [
      lineDiscussion('disc-1'),
      lineDiscussion('disc-2', { oldLine: 2 }),
    ];
    await nextTick();
    expect(mockDismiss).toHaveBeenCalledTimes(1);
    expect(createAlert).toHaveBeenCalledTimes(2);
  });

  it('dismisses the alert on cleanup', async () => {
    const mockDismiss = jest.fn();
    createAlert.mockReturnValue({ dismiss: mockDismiss });
    mountAdapter();
    useDiscussions().discussions = [lineDiscussion('disc-1')];
    await nextTick();
    getDiffFile().remove();
    expect(mockDismiss).toHaveBeenCalled();
  });
});
