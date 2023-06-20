import { shallowMount } from '@vue/test-utils';
import discussionFixture from 'test_fixtures/merge_requests/diff_discussion.json';
import imageDiscussionFixture from 'test_fixtures/merge_requests/image_diff_discussion.json';
import { createStore } from '~/mr_notes/stores';
import DiffWithNote from '~/notes/components/diff_with_note.vue';
import DiffViewer from '~/vue_shared/components/diff_viewer/diff_viewer.vue';

describe('diff_with_note', () => {
  let store;
  let wrapper;

  const selectors = {
    get diffTable() {
      return wrapper.find('.diff-content table');
    },
    get diffRows() {
      return wrapper.findAll('.diff-content .line_holder');
    },
    get noteRow() {
      return wrapper.find('.diff-content .notes_holder');
    },
  };

  const findDiffViewer = () => wrapper.findComponent(DiffViewer);

  beforeEach(() => {
    store = createStore();
    store.replaceState({
      ...store.state,
      notes: {
        noteableData: {
          current_user: {},
        },
      },
    });
  });

  describe('text diff', () => {
    beforeEach(() => {
      const diffDiscussion = discussionFixture[0];

      wrapper = shallowMount(DiffWithNote, {
        propsData: {
          discussion: diffDiscussion,
        },
        store,
      });
    });

    it('removes trailing "+" char', () => {
      const richText = wrapper.vm.$el
        .querySelectorAll('.line_holder')[4]
        .querySelector('.line_content').textContent[0];

      expect(richText).not.toEqual('+');
    });

    it('removes trailing "-" char', () => {
      const richText = wrapper.vm.$el.querySelector('#LC13').parentNode.textContent[0];

      expect(richText).not.toEqual('-');
    });

    it('shows text diff', () => {
      expect(wrapper.classes('text-file')).toBe(true);
      expect(selectors.diffTable.exists()).toBe(true);
    });

    it('shows diff lines', () => {
      expect(selectors.diffRows.length).toBe(12);
    });

    it('shows notes row', () => {
      expect(selectors.noteRow.exists()).toBe(true);
    });
  });

  describe('image diff', () => {
    beforeEach(() => {
      const imageDiscussion = imageDiscussionFixture[0];
      wrapper = shallowMount(DiffWithNote, {
        propsData: { discussion: imageDiscussion, diffFile: {} },
        store,
      });
    });

    it('shows image diff', () => {
      expect(selectors.diffTable.exists()).toBe(false);
    });
  });

  describe('legacy diff note', () => {
    const mockCommitId = 'abc123';

    beforeEach(() => {
      const diffDiscussion = {
        ...discussionFixture[0],
        commit_id: mockCommitId,
        diff_file: {
          ...discussionFixture[0].diff_file,
          diff_refs: null,
          viewer: {
            ...discussionFixture[0].diff_file.viewer,
            name: 'no_preview',
          },
        },
      };

      wrapper = shallowMount(DiffWithNote, {
        propsData: {
          discussion: diffDiscussion,
        },
        store,
      });
    });

    it('shows file diff', () => {
      expect(selectors.diffTable.exists()).toBe(false);
    });

    it('uses "no_preview" diff mode', () => {
      expect(findDiffViewer().props('diffMode')).toBe('no_preview');
    });

    it('falls back to discussion.commit_id for baseSha and headSha', () => {
      expect(findDiffViewer().props('oldSha')).toBe(mockCommitId);
      expect(findDiffViewer().props('newSha')).toBe(mockCommitId);
    });
  });
});
