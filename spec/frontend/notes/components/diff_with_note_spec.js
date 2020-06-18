import { shallowMount } from '@vue/test-utils';
import DiffWithNote from '~/notes/components/diff_with_note.vue';
import { createStore } from '~/mr_notes/stores';

const discussionFixture = 'merge_requests/diff_discussion.json';
const imageDiscussionFixture = 'merge_requests/image_diff_discussion.json';

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
      const diffDiscussion = getJSONFixture(discussionFixture)[0];

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
      const imageDiscussion = getJSONFixture(imageDiscussionFixture)[0];
      wrapper = shallowMount(DiffWithNote, {
        propsData: { discussion: imageDiscussion, diffFile: {} },
        store,
      });
    });

    it('shows image diff', () => {
      expect(selectors.diffTable.exists()).toBe(false);
    });
  });
});
