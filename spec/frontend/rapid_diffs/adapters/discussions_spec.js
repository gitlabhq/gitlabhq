import { nextTick } from 'vue';
import { setActivePinia } from 'pinia';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import {
  inlineDiscussionsAdapter,
  parallelDiscussionsAdapter,
} from '~/rapid_diffs/adapters/discussions';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import { pinia } from '~/pinia/instance';

describe('discussions adapters', () => {
  const oldPath = 'old';
  const newPath = 'new';

  const getDiffFile = () => document.querySelector('diff-file');
  const getDiscussionRows = () => getDiffFile().querySelectorAll('[data-discussion-row]');

  beforeEach(() => {
    setActivePinia(pinia);
  });

  afterEach(() => {
    useDiffDiscussions().discussions = [];
    resetHTMLFixture();
  });

  beforeAll(() => {
    customElements.define('diff-file', DiffFile);
  });

  describe('inlineDiscussionsAdapter', () => {
    beforeEach(() => {
      const fileData = { viewer: 'text_inline', old_path: oldPath, new_path: newPath };
      setHTMLFixture(`
        <diff-file data-file-data='${JSON.stringify(fileData)}'>
          <div>
            <table>
              <thead><tr><td></td><td></td></tr></thead>
              <tbody>
                <tr>
                  <td data-position="old"><a data-line-number="1"></a></td>
                  <td></td>
                </tr>
                <tr>
                  <td data-position="new"><a data-line-number="1"></a></td>
                  <td></td>
                </tr>
                <tr>
                  <td data-position="old"><a data-line-number="2"></a></td>
                  <td></td>
                </tr>
              </tbody>
            </table>
          </div>
        </diff-file>
      `);
      getDiffFile().mount({
        adapterConfig: { text_inline: [inlineDiscussionsAdapter] },
        appData: {},
        unobserve: jest.fn(),
      });
    });

    it('renders a discussion', async () => {
      const discussionId = 'abc';
      const oldLine = 1;
      useDiffDiscussions().discussions = [
        {
          id: discussionId,
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: oldLine, new_line: null },
        },
      ];
      await nextTick();
      const [discussionRow] = getDiscussionRows();
      const previousRow = discussionRow.previousElementSibling;
      expect(previousRow.querySelector('[data-line-number]').dataset.lineNumber).toBe(
        oldLine.toString(),
      );
      expect(discussionRow.querySelector('td').textContent).toBe(
        `This is a discussion placeholder with an id: ${discussionId}`,
      );
    });

    it('does not render discussions for different paths', async () => {
      useDiffDiscussions().discussions = [
        {
          id: 'xyz',
          diff_discussion: true,
          position: { old_path: 'different', new_path: 'paths', old_line: 1, new_line: null },
        },
      ];
      await nextTick();
      expect(getDiffFile().querySelector('[data-discussion-id]')).toBeNull();
    });

    it('creates only one discussion row when multiple discussions share the same position', async () => {
      const oldLine = 1;
      useDiffDiscussions().discussions = [
        {
          id: 'first',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: oldLine, new_line: null },
        },
        {
          id: 'second',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: oldLine, new_line: null },
        },
      ];
      await nextTick();

      const discussionRows = getDiscussionRows();
      expect(discussionRows).toHaveLength(1);
      expect(discussionRows[0].querySelectorAll('td')).toHaveLength(1);
    });
  });

  describe('parallelDiscussionsAdapter', () => {
    beforeEach(() => {
      const fileData = { viewer: 'text_parallel', old_path: oldPath, new_path: newPath };
      setHTMLFixture(`
        <diff-file data-file-data='${JSON.stringify(fileData)}'>
          <div>
            <table>
              <thead><tr><td></td><td></td></tr></thead>
              <tbody>
                <tr>
                  <td data-position="old"><a data-line-number="1"></a></td>
                  <td></td>
                  <td data-position="new"><a data-line-number="1"></a></td>
                  <td></td>
                </tr>
                <tr>
                  <td data-position="old"><a data-line-number="2"></a></td>
                  <td></td>
                  <td data-position="new"><a data-line-number="2"></a></td>
                  <td></td>
                </tr>
              </tbody>
            </table>
          </div>
        </diff-file>
      `);
      getDiffFile().mount({
        adapterConfig: { text_parallel: [parallelDiscussionsAdapter] },
        appData: {},
        unobserve: jest.fn(),
      });
    });

    it('renders a discussion on the old side', async () => {
      const discussionId = 'old-side';
      const oldLine = 1;
      useDiffDiscussions().discussions = [
        {
          id: discussionId,
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: oldLine, new_line: null },
        },
      ];
      await nextTick();
      const [discussionRow] = getDiscussionRows();
      const previousRow = discussionRow.previousElementSibling;
      expect(
        previousRow.querySelector('[data-position="old"] [data-line-number]').dataset.lineNumber,
      ).toBe(oldLine.toString());
      expect(discussionRow.children[0].textContent).toBe(
        `This is a discussion placeholder with an id: ${discussionId}`,
      );
    });

    it('renders a discussion on the new side', async () => {
      const discussionId = 'new-side';
      const newLine = 2;
      useDiffDiscussions().discussions = [
        {
          id: discussionId,
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: null, new_line: newLine },
        },
      ];
      await nextTick();
      const [discussionRow] = getDiscussionRows();
      const previousRow = discussionRow.previousElementSibling;
      expect(
        previousRow.querySelector('[data-position="new"] [data-line-number]').dataset.lineNumber,
      ).toBe(newLine.toString());
      expect(discussionRow.children[1].textContent).toBe(
        `This is a discussion placeholder with an id: ${discussionId}`,
      );
    });

    it('renders a discussion on both sides', async () => {
      const leftDiscussionId = 'left';
      const rightDiscussionId = 'right';
      const oldLine = 1;
      const newLine = 1;
      useDiffDiscussions().discussions = [
        {
          id: leftDiscussionId,
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: oldLine, new_line: null },
        },
        {
          id: rightDiscussionId,
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: null, new_line: newLine },
        },
      ];
      await nextTick();
      const [discussionRow] = getDiscussionRows();
      expect(discussionRow.children[0].textContent).toBe(
        `This is a discussion placeholder with an id: ${leftDiscussionId}`,
      );
      expect(discussionRow.children[1].textContent).toBe(
        `This is a discussion placeholder with an id: ${rightDiscussionId}`,
      );
    });

    it('renders a discussion spanning both sides', async () => {
      const discussionId = 'both-sides';
      const oldLine = 1;
      const newLine = 1;
      useDiffDiscussions().discussions = [
        {
          id: discussionId,
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: oldLine, new_line: newLine },
        },
      ];
      await nextTick();
      const [discussionRow] = getDiscussionRows();
      expect(discussionRow.children).toHaveLength(1);
      expect(discussionRow.children[0].textContent).toBe(
        `This is a discussion placeholder with an id: ${discussionId}`,
      );
    });

    it('does not render discussions for different paths', async () => {
      useDiffDiscussions().discussions = [
        {
          id: 'xyz',
          diff_discussion: true,
          position: { old_path: 'different', new_path: 'paths', old_line: 1, new_line: null },
        },
      ];
      await nextTick();
      expect(getDiffFile().querySelector('[data-discussion-id]')).toBeNull();
    });

    it('creates only one discussion row when multiple discussions share the same position', async () => {
      const oldLine = 1;
      useDiffDiscussions().discussions = [
        {
          id: 'first',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: oldLine, new_line: null },
        },
        {
          id: 'second',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: oldLine, new_line: null },
        },
      ];
      await nextTick();

      const discussionRows = getDiscussionRows();
      expect(discussionRows).toHaveLength(1);
      expect(discussionRows[0].querySelectorAll('td')).toHaveLength(2);
    });
  });
});
