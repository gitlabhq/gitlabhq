import { nextTick } from 'vue';
import { setActivePinia } from 'pinia';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import { createFileDiscussionsAdapter } from '~/rapid_diffs/adapters/file_discussions';
import { DiffFile } from '~/rapid_diffs/web_components/diff_file';
import { useDiffDiscussions } from '~/rapid_diffs/stores/diff_discussions';
import { useDiscussions } from '~/notes/store/discussions';
import { pinia } from '~/pinia/instance';

jest.mock('~/rapid_diffs/app/discussions/diff_file_discussions.vue', () => {
  return {
    inject: [
      'filePaths',
      'diffRefs',
      'linkedFileData',
      'newCommentTemplatePaths',
      'showWhitespace',
    ],
    methods: {
      empty() {
        this.$emit('empty');
      },
    },
    mounted() {
      this.$el.instance = () => this;
    },
    beforeDestroy() {
      this.$el.onDestroy?.();
    },
    render(h) {
      return h('div', {
        attrs: {
          id: 'file-discussions-component',
          'data-file-paths': JSON.stringify(this.filePaths),
          'data-diff-refs': JSON.stringify(this.diffRefs),
          'data-linked-file-data': JSON.stringify(this.linkedFileData),
          'data-new-comment-template-paths': JSON.stringify(this.newCommentTemplatePaths),
          'data-show-whitespace': JSON.stringify(this.showWhitespace),
        },
      });
    },
  };
});

describe('fileDiscussionsAdapter', () => {
  const oldPath = 'old';
  const newPath = 'new';
  const linkedFileData = { old_path: oldPath, new_path: newPath };
  const newCommentTemplatePaths = [
    { text: 'Your comment templates', href: '/-/profile/comment_templates' },
  ];
  const appData = {
    userPermissions: { can_create_note: true },
    discussionsEndpoint: 'discussionsEndpoint',
    previewMarkdownEndpoint: 'previewMarkdownEndpoint',
    markdownDocsEndpoint: 'markdownDocsEndpoint',
    registerPath: 'registerPath',
    signInPath: 'signInPath',
    noteableType: 'MergeRequest',
    reportAbusePath: 'reportAbusePath',
    linkedFileData,
    newCommentTemplatePaths,
  };

  const getDiffFile = () => document.querySelector('diff-file');
  const getFileDiscussionsContainer = () => getDiffFile().querySelector('[data-file-discussions]');
  const getFileDiscussionsComponent = () =>
    getDiffFile().querySelector('#file-discussions-component');

  let store;

  beforeEach(() => {
    setActivePinia(pinia);
    store = useDiffDiscussions();
  });

  afterEach(() => {
    useDiscussions().discussions = [];
    store.discussionForms = [];
    resetHTMLFixture();
  });

  if (!customElements.get('diff-file')) {
    customElements.define('diff-file', DiffFile);
  }

  const mountAdapter = (extraFileData = {}) => {
    const fileData = {
      viewer: 'text_inline',
      old_path: oldPath,
      new_path: newPath,
      ...extraFileData,
    };
    setHTMLFixture(`
      <diff-file data-file-data='${JSON.stringify(fileData)}'>
        <div>
          <button disabled aria-disabled="true" data-click="fileComment"></button>
          <div data-file-discussions></div>
        </div>
      </diff-file>
    `);
    getDiffFile().mount({
      adapterConfig: { text_inline: [createFileDiscussionsAdapter(store)] },
      appData,
      unobserve: jest.fn(),
    });
  };

  it('enables the file comment toggle button on mount', () => {
    mountAdapter();
    const button = getDiffFile().querySelector('[data-click="fileComment"]');
    expect(button.disabled).toBe(false);
    expect(button.hasAttribute('aria-disabled')).toBe(false);
  });

  it('mounts file discussions component when file discussions exist', async () => {
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
    expect(getFileDiscussionsComponent()).not.toBeNull();
  });

  it('mounts file discussions component when file discussions are hidden', async () => {
    mountAdapter();
    useDiscussions().discussions = [
      {
        id: 'file-disc',
        diff_discussion: true,
        hidden: true,
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
    expect(getFileDiscussionsComponent()).not.toBeNull();
  });

  it('provides filePaths to the component', async () => {
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
    expect(JSON.parse(getFileDiscussionsComponent().dataset.filePaths)).toStrictEqual({
      oldPath,
      newPath,
    });
    expect(JSON.parse(getFileDiscussionsComponent().dataset.linkedFileData)).toStrictEqual(
      linkedFileData,
    );
    expect(JSON.parse(getFileDiscussionsComponent().dataset.newCommentTemplatePaths)).toStrictEqual(
      newCommentTemplatePaths,
    );
  });

  it('provides the diff file refs to the component', async () => {
    const diffRefs = { base_sha: 'base', start_sha: 'start', head_sha: 'head' };
    mountAdapter({ diff_refs: diffRefs });
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
    expect(JSON.parse(getFileDiscussionsComponent().dataset.diffRefs)).toStrictEqual(diffRefs);
  });

  it('does not mount when there are no file discussions', async () => {
    mountAdapter();
    useDiscussions().discussions = [
      {
        id: 'line-disc',
        diff_discussion: true,
        position: { old_path: oldPath, new_path: newPath, old_line: 1, new_line: null },
      },
    ];
    await nextTick();
    expect(getFileDiscussionsComponent()).toBeNull();
  });

  it('does not mount for discussions on different paths', async () => {
    mountAdapter();
    useDiscussions().discussions = [
      {
        id: 'other-file',
        diff_discussion: true,
        position: {
          old_path: 'other',
          new_path: 'other',
          position_type: 'file',
          old_line: null,
          new_line: null,
        },
      },
    ];
    await nextTick();
    expect(getFileDiscussionsComponent()).toBeNull();
  });

  it('creates file discussion form on fileComment click', async () => {
    mountAdapter();
    let event;
    const button = getDiffFile().querySelector('[data-click="fileComment"]');
    button.addEventListener('click', (e) => {
      event = e;
    });
    button.click();
    getDiffFile().onClick(event);
    await nextTick();
    expect(store.discussionForms).toHaveLength(1);
    expect(store.discussionForms[0].position.position_type).toBe('file');
  });

  it('cleans up on removal', async () => {
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
    const onDestroy = jest.fn();
    getFileDiscussionsComponent().onDestroy = onDestroy;
    getDiffFile().remove();
    expect(onDestroy).toHaveBeenCalled();
  });

  describe('showWhitespace provide', () => {
    const fileDiscussion = {
      id: 'file-disc',
      diff_discussion: true,
      position: {
        old_path: oldPath,
        new_path: newPath,
        position_type: 'file',
        old_line: null,
        new_line: null,
      },
    };

    it('provides showWhitespace from this.data when set on the diff-file element', async () => {
      mountAdapter({ show_whitespace: true });
      useDiscussions().discussions = [fileDiscussion];
      await nextTick();
      expect(JSON.parse(getFileDiscussionsComponent().dataset.showWhitespace)).toBe(true);
    });

    it('provides undefined showWhitespace when not set on the diff-file element', async () => {
      mountAdapter();
      useDiscussions().discussions = [fileDiscussion];
      await nextTick();
      expect(getFileDiscussionsComponent().dataset.showWhitespace).toBeUndefined();
    });
  });

  it('cleans up component on empty event', async () => {
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
    getFileDiscussionsComponent().instance().empty();
    await nextTick();
    expect(getFileDiscussionsContainer().innerHTML).toBe('');
  });
});
