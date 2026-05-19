import { nextTick } from 'vue';
import { defineStore } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import { kebabCase } from 'lodash-es';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import { createLineDiscussionsAdapter } from '~/rapid_diffs/adapters/line_discussions';
import { HIGHLIGHT_LINES, CLEAR_HIGHLIGHT } from '~/rapid_diffs/adapter_events';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { createAlert } from '~/alert';

jest.mock('~/alert');

const useDiscussionsStore = defineStore('discussionsStore', {
  state: () => ({
    discussions: [],
  }),
  actions: {
    findLinePositionsForFile() {
      return this.discussions.map((d) => d.position);
    },
    findLineDiscussionsForPosition() {
      return this.discussions;
    },
    addNewLineDiscussionForm() {},
    setPositionDiscussionsHidden() {},
    setFileDiscussionsHidden() {},
    startReplying() {},
    stopReplying() {},
  },
});

// jest fails with direct usage of lodash inside jest.mock
const toKebab = (str) => kebabCase(str);

jest.mock('~/rapid_diffs/app/discussions/diff_line_discussions.vue', () => {
  return {
    props: jest.requireActual('~/rapid_diffs/app/discussions/diff_line_discussions.vue').default
      .props,
    inject: [
      'userPermissions',
      'endpoints',
      'noteableType',
      'filePaths',
      'blobRawPath',
      'suggestionsHelpPath',
      'defaultSuggestionCommitMessage',
      'linkedFileData',
      'newCommentTemplatePaths',
    ],
    methods: {
      empty() {
        this.$emit('empty');
      },
      emitHighlight(lineRange) {
        this.$emit('highlight', lineRange);
      },
      emitClearHighlight() {
        this.$emit('clear-highlight');
      },
      startThread(position) {
        this.$emit('start-thread', position);
      },
    },
    mounted() {
      this.$el.instance = () => this;
    },
    beforeDestroy() {
      this.$el.onDestroy?.();
    },
    render(h) {
      const renderAsDataAttr = (key, value) => {
        return h('div', { attrs: { [`data-${toKebab(key)}`]: JSON.stringify(value) } });
      };
      const props = Object.keys(this.$props).map((key) => {
        return renderAsDataAttr(key, this.$props[key]);
      });
      const injected = [
        renderAsDataAttr('user-permissions', this.userPermissions),
        renderAsDataAttr('endpoints', this.endpoints),
        renderAsDataAttr('noteable-type', this.noteableType),
        renderAsDataAttr('file-paths', this.filePaths),
        renderAsDataAttr('blob-raw-path', this.blobRawPath),
        renderAsDataAttr('suggestions-help-path', this.suggestionsHelpPath),
        renderAsDataAttr('default-suggestion-commit-message', this.defaultSuggestionCommitMessage),
        renderAsDataAttr('linked-file-data', this.linkedFileData),
        renderAsDataAttr('new-comment-template-paths', this.newCommentTemplatePaths),
      ];
      return h('div', { attrs: { id: 'discussions-component' } }, [...props, ...injected]);
    },
  };
});

jest.mock('~/rapid_diffs/app/discussions/new_line_discussion_form.vue', () => {
  return {
    render(h) {
      return h('div', { attrs: { 'data-new-discussion-form': true } });
    },
  };
});

describe('discussions adapters', () => {
  const oldPath = 'old';
  const newPath = 'new';
  const userPermissions = { can_create_note: true };
  const endpoints = {
    previewMarkdown: 'previewMarkdownEndpoint',
    markdownDocs: 'markdownDocsEndpoint',
    register: 'registerPath',
    signIn: 'signInPath',
    reportAbuse: 'reportAbusePath',
  };
  const linkedFileData = { old_path: oldPath, new_path: newPath };
  const newCommentTemplatePaths = [
    { text: 'Your comment templates', href: '/-/profile/comment_templates' },
  ];
  const appData = {
    userPermissions,
    previewMarkdownEndpoint: 'previewMarkdownEndpoint',
    markdownDocsEndpoint: 'markdownDocsEndpoint',
    registerPath: 'registerPath',
    signInPath: 'signInPath',
    noteableType: 'Commit',
    reportAbusePath: 'reportAbusePath',
    suggestionsHelpPath: '/help/suggestions',
    defaultSuggestionCommitMessage: 'Apply suggestion',
    linkedFileData,
    newCommentTemplatePaths,
  };

  const getDiffFile = () => document.querySelector('diff-file');
  const getDiscussionRows = () => getDiffFile().querySelectorAll('[data-discussion-row]');

  let store;

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useDiscussionsStore();
  });

  afterEach(() => {
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
                <tr data-hunk-lines>
                  <td data-position="old" data-change="removed"><a data-line-number="1"></a></td>
                  <td></td>
                </tr>
                <tr data-hunk-lines>
                  <td data-position="new" data-change="added"><a data-line-number="1"></a></td>
                  <td></td>
                </tr>
                <tr data-hunk-lines>
                  <td data-position="old">
                    <button data-click="newDiscussion"></button>
                    <a data-line-number="2"></a>
                  </td>
                  <td></td>
                </tr>
              </tbody>
            </table>
          </div>
        </diff-file>
      `);
      getDiffFile().mount({
        adapterConfig: {
          text_inline: [
            createLineDiscussionsAdapter({ store, parallel: false, errorMessage: 'test error' }),
          ],
        },
        appData,
        unobserve: jest.fn(),
      });
    });

    it('renders a discussion row', async () => {
      store.discussions = [
        {
          id: 'abc',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 1, new_line: null },
        },
      ];
      await nextTick();
      const [discussionRow] = getDiscussionRows();
      const codeRow = discussionRow.previousElementSibling;
      expect(codeRow.querySelector('[data-line-number]').dataset.lineNumber).toBe('1');
    });

    it('provides app data', async () => {
      store.discussions = [
        {
          id: 'abc',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 1, new_line: null },
        },
      ];
      await nextTick();
      expect(
        JSON.parse(document.querySelector('[data-user-permissions]').dataset.userPermissions),
      ).toStrictEqual(userPermissions);
      expect(
        JSON.parse(document.querySelector('[data-endpoints]').dataset.endpoints),
      ).toStrictEqual(endpoints);
      expect(
        JSON.parse(document.querySelector('[data-noteable-type]').dataset.noteableType),
      ).toStrictEqual('Commit');
      expect(
        JSON.parse(document.querySelector('[data-file-paths]').dataset.filePaths),
      ).toStrictEqual({ oldPath, newPath });
      expect(
        JSON.parse(document.querySelector('[data-linked-file-data]').dataset.linkedFileData),
      ).toStrictEqual(linkedFileData);
      expect(
        JSON.parse(
          document.querySelector('[data-suggestions-help-path]').dataset.suggestionsHelpPath,
        ),
      ).toBe('/help/suggestions');
      expect(
        JSON.parse(
          document.querySelector('[data-default-suggestion-commit-message]').dataset
            .defaultSuggestionCommitMessage,
        ),
      ).toBe('Apply suggestion');
      expect(
        JSON.parse(
          document.querySelector('[data-new-comment-template-paths]').dataset
            .newCommentTemplatePaths,
        ),
      ).toStrictEqual(newCommentTemplatePaths);
    });

    it('mounts discussion row for hidden discussions', async () => {
      store.discussions = [
        {
          id: 'hidden-discussion',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 1, new_line: null },
          hidden: true,
        },
      ];
      await nextTick();
      expect(getDiscussionRows()).toHaveLength(1);
    });

    it('creates only one discussion row per line', async () => {
      store.discussions = [
        {
          id: 'first',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 1, new_line: null },
        },
        {
          id: 'second',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 1, new_line: null },
        },
      ];
      await nextTick();
      const discussionRows = getDiscussionRows();
      expect(discussionRows).toHaveLength(1);
      expect(discussionRows[0].querySelectorAll('td')).toHaveLength(1);
    });

    it('removes empty row', async () => {
      store.discussions = [
        {
          id: 'abc',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 1, new_line: null },
        },
      ];
      await nextTick();
      expect(getDiscussionRows()).toHaveLength(1);
      store.discussions = [];
      await nextTick();
      expect(getDiscussionRows()).toHaveLength(0);
    });

    it('skips mounting when discussion line is not found', async () => {
      store.discussions = [
        {
          id: 'abc',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 999, new_line: null },
        },
      ];
      await nextTick();
      expect(createAlert).not.toHaveBeenCalled();
      expect(getDiscussionRows()).toHaveLength(0);
    });

    it('forwards click to store', () => {
      let event;
      const button = getDiffFile().querySelector('[data-click="newDiscussion"]');
      const pos = { old_line: 2, new_line: null, type: null };
      const lineRange = { start: pos, end: pos };
      button.lineRange = lineRange;
      button.addEventListener('click', (e) => {
        event = e;
      });
      button.click();
      getDiffFile().onClick(event);
      expect(store.addNewLineDiscussionForm).toHaveBeenCalledWith(
        expect.objectContaining({ oldPath, newPath, lineRange }),
      );
      expect(store.addNewLineDiscussionForm).toHaveBeenCalledWith(
        expect.objectContaining({ lineRange, lineCode: expect.stringMatching(/_\d+_\d+$/) }),
      );
    });

    it('resolves lineCode on start-thread from discussion row', async () => {
      store.discussions = [
        {
          id: 'abc',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 1, new_line: null },
        },
      ];
      await nextTick();
      const row = getDiscussionRows()[0];
      row.querySelector('#discussions-component').instance().startThread({
        oldPath,
        newPath,
        oldLine: 1,
        newLine: null,
      });
      expect(store.addNewLineDiscussionForm).toHaveBeenCalledWith(
        expect.objectContaining({
          oldPath,
          newPath,
          lineCode: expect.stringMatching(/_\d+_\d+$/),
        }),
      );
    });

    it('keeps discussion row when discussions are hidden', async () => {
      const oldLine = 1;
      store.discussions = [
        {
          id: 'abc',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: oldLine, new_line: null },
        },
      ];
      await nextTick();
      expect(getDiscussionRows()).toHaveLength(1);
      store.setFileDiscussionsHidden(oldPath, newPath, true);
      await nextTick();
      expect(getDiscussionRows()).toHaveLength(1);
    });

    it('destroys Vue instances on cleanup', async () => {
      store.discussions = [
        {
          id: 'abc',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 1, new_line: null },
        },
      ];
      await nextTick();
      const onDestroy = jest.fn();
      document.querySelector('#discussions-component').onDestroy = onDestroy;
      getDiffFile().remove();
      expect(onDestroy).toHaveBeenCalled();
    });

    describe('line highlighting events', () => {
      const highlightSpy = jest.fn();
      const clearHighlightSpy = jest.fn();

      beforeEach(() => {
        highlightSpy.mockClear();
        clearHighlightSpy.mockClear();
        resetHTMLFixture();
        const fileData = { viewer: 'text_inline', old_path: oldPath, new_path: newPath };
        setHTMLFixture(`
          <diff-file data-file-data='${JSON.stringify(fileData)}'>
            <div>
              <table>
                <thead><tr><td></td><td></td></tr></thead>
                <tbody>
                  <tr data-hunk-lines>
                    <td data-position="old"><a data-line-number="1"></a></td>
                    <td></td>
                  </tr>
                </tbody>
              </table>
            </div>
          </diff-file>
        `);
        const spyAdapter = {
          [HIGHLIGHT_LINES]: highlightSpy,
          [CLEAR_HIGHLIGHT]: clearHighlightSpy,
        };
        getDiffFile().mount({
          adapterConfig: {
            text_inline: [createLineDiscussionsAdapter({ store, parallel: false }), spyAdapter],
          },
          appData,
          unobserve: jest.fn(),
        });
      });

      it('calls trigger with HIGHLIGHT_LINES when Vue component emits highlight', async () => {
        store.discussions = [
          {
            id: 'abc',
            diff_discussion: true,
            position: { old_path: oldPath, new_path: newPath, old_line: 1, new_line: null },
          },
        ];
        await nextTick();
        const lineRange = { start: { old_line: 1 }, end: { old_line: 1 } };
        document.querySelector('#discussions-component').instance().emitHighlight(lineRange);
        expect(highlightSpy).toHaveBeenCalledWith(lineRange);
      });

      it('calls trigger with CLEAR_HIGHLIGHT when Vue component emits clear-highlight', async () => {
        store.discussions = [
          {
            id: 'abc',
            diff_discussion: true,
            position: { old_path: oldPath, new_path: newPath, old_line: 1, new_line: null },
          },
        ];
        await nextTick();
        document.querySelector('#discussions-component').instance().emitClearHighlight();
        expect(clearHighlightSpy).toHaveBeenCalled();
      });

      it('triggers CLEAR_HIGHLIGHT when discussion row becomes empty', async () => {
        store.discussions = [
          {
            id: 'abc',
            diff_discussion: true,
            position: { old_path: oldPath, new_path: newPath, old_line: 1, new_line: null },
          },
        ];
        await nextTick();
        expect(getDiscussionRows()).toHaveLength(1);
        store.discussions = [];
        await nextTick();
        expect(clearHighlightSpy).toHaveBeenCalled();
      });
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
                <tr data-hunk-lines>
                  <td data-position="old"><a data-line-number="1"></a></td>
                  <td></td>
                  <td data-position="new"></td>
                  <td></td>
                </tr>
                <tr data-hunk-lines>
                  <td data-position="old"></td>
                  <td></td>
                  <td data-position="new"><a data-line-number="2"></a></td>
                  <td></td>
                </tr>
                <tr data-hunk-lines>
                  <td data-position="old"><a data-line-number="3"></a></td>
                  <td></td>
                  <td data-position="new"><a data-line-number="3"></a></td>
                  <td></td>
                </tr>
                <tr data-hunk-lines>
                  <td data-position="old"><a data-line-number="4"></a></td>
                  <td></td>
                  <td data-position="new">
                    <button data-click="newDiscussion"></button>
                    <a data-line-number="4"></a>
                  </td>
                  <td></td>
                </tr>
                <tr data-hunk-lines>
                  <td data-change="removed" data-position="old"><a data-line-number="5"></a></td>
                  <td data-change="removed"></td>
                  <td data-change="added" data-position="new"><a data-line-number="5"></a></td>
                  <td data-change="added"></td>
                </tr>
              </tbody>
            </table>
          </div>
        </diff-file>
      `);
      getDiffFile().mount({
        adapterConfig: { text_parallel: [createLineDiscussionsAdapter({ store, parallel: true })] },
        appData: {},
        unobserve: jest.fn(),
      });
    });

    it('renders a discussion on the old side', async () => {
      store.discussions = [
        {
          id: 'old-side',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 1, new_line: null },
        },
      ];
      await nextTick();
      const [discussionRow] = getDiscussionRows();
      const codeRow = discussionRow.previousElementSibling;
      expect(
        codeRow.querySelector('[data-position="old"] [data-line-number]').dataset.lineNumber,
      ).toBe('1');
      expect(discussionRow.children).toHaveLength(2);
    });

    it('renders a discussion on the new side', async () => {
      store.discussions = [
        {
          id: 'new-side',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: null, new_line: 2 },
        },
      ];
      await nextTick();
      const [discussionRow] = getDiscussionRows();
      const codeRow = discussionRow.previousElementSibling;
      expect(
        codeRow.querySelector('[data-position="new"] [data-line-number]').dataset.lineNumber,
      ).toBe('2');
      expect(discussionRow.children).toHaveLength(2);
    });

    it('renders discussions on both sides of a modified row', async () => {
      store.discussions = [
        {
          id: 'old-side',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 5, new_line: null },
        },
        {
          id: 'new-side',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: null, new_line: 5 },
        },
      ];
      await nextTick();
      const discussionRows = getDiscussionRows();
      expect(discussionRows).toHaveLength(1);
      expect(discussionRows[0].children).toHaveLength(2);
    });

    it('renders a discussion spanning both sides', async () => {
      store.discussions = [
        {
          id: 'spanning',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 3, new_line: 3 },
        },
      ];
      await nextTick();
      const [discussionRow] = getDiscussionRows();
      expect(discussionRow.children).toHaveLength(1);
    });

    it('creates only one discussion row per line', async () => {
      store.discussions = [
        {
          id: 'first',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 1, new_line: null },
        },
        {
          id: 'second',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 1, new_line: null },
        },
      ];
      await nextTick();
      const discussionRows = getDiscussionRows();
      expect(discussionRows).toHaveLength(1);
      expect(discussionRows[0].querySelectorAll('td')).toHaveLength(2);
    });

    it('forwards click to store.addNewLineDiscussionForm', () => {
      let event;
      const button = getDiffFile().querySelector('[data-click="newDiscussion"]');
      const pos = { old_line: 4, new_line: 4, type: null };
      const lineRange = { start: pos, end: pos };
      button.lineRange = lineRange;
      button.addEventListener('click', (e) => {
        event = e;
      });
      button.click();
      getDiffFile().onClick(event);

      expect(store.addNewLineDiscussionForm).toHaveBeenCalledWith(
        expect.objectContaining({
          oldPath,
          newPath,
          lineCode: expect.stringMatching(/_\d+_\d+$/),
          lineChange: { change: undefined, position: 'new' },
          lineRange,
        }),
      );
    });

    it('includes lineCode in the created form', () => {
      let event;
      const button = getDiffFile().querySelector('[data-click="newDiscussion"]');
      const pos = { old_line: 1, new_line: 1 };
      button.lineRange = { start: pos, end: pos };
      button.addEventListener('click', (e) => {
        event = e;
      });
      button.click();
      getDiffFile().onClick(event);
      expect(store.addNewLineDiscussionForm).toHaveBeenCalledWith(
        expect.objectContaining({ lineCode: expect.stringMatching(/_\d+_\d+$/) }),
      );
    });

    it('resolves lineChange per side on start-thread from discussion row', async () => {
      store.discussions = [
        {
          id: 'abc',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 5, new_line: null },
        },
      ];
      await nextTick();
      const row = getDiscussionRows()[0];
      row.querySelector('#discussions-component').instance().startThread({
        oldPath,
        newPath,
        oldLine: 5,
        newLine: null,
      });
      expect(store.addNewLineDiscussionForm).toHaveBeenCalledWith(
        expect.objectContaining({
          lineChange: { change: 'removed', position: 'old' },
          lineCode: expect.stringMatching(/_\d+_\d+$/),
        }),
      );
    });

    it('resolves lineChange for an unchanged line on start-thread from discussion row', async () => {
      store.discussions = [
        {
          id: 'abc',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 3, new_line: 3 },
        },
      ];
      await nextTick();
      const row = getDiscussionRows()[0];
      row.querySelector('#discussions-component').instance().startThread({
        oldPath,
        newPath,
        oldLine: 3,
        newLine: 3,
      });
      expect(store.addNewLineDiscussionForm).toHaveBeenCalledWith(
        expect.objectContaining({
          lineChange: { change: undefined, position: 'old' },
          lineCode: expect.stringMatching(/_\d+_\d+$/),
        }),
      );
    });

    it('removes empty row', async () => {
      store.discussions = [
        {
          id: 'abc',
          diff_discussion: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 1, new_line: null },
        },
      ];
      await nextTick();
      expect(getDiscussionRows()).toHaveLength(1);
      store.discussions = [];
      await nextTick();
      expect(getDiscussionRows()).toHaveLength(0);
    });
  });
});
