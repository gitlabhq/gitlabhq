import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { defineStore } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import setWindowLocation from 'helpers/set_window_location_helper';
import DiffFileDiscussions from '~/rapid_diffs/app/discussions/diff_file_discussions.vue';
import DiffDiscussions from '~/rapid_diffs/app/discussions/diff_discussions.vue';
import DiffFileDiscussionExpansion from '~/diffs/components/diff_file_discussion_expansion.vue';
import DraftNote from '~/rapid_diffs/app/discussions/draft_note.vue';
import NoteForm from '~/rapid_diffs/app/discussions/note_form.vue';

const useMockStore = defineStore('fileDiscussionsTestStore', {
  state: () => ({
    discussions: [],
  }),
  actions: {
    findAllFileDiscussionsForFile() {
      return this.discussions;
    },
    expandFileDiscussions() {
      this.discussions = this.discussions.map((d) => ({ ...d, hidden: false }));
    },
    setInitialDiscussions(discussions) {
      this.discussions = discussions;
    },
    removeNewFileDiscussionForm() {},
    createFileDiscussion() {},
    setDiscussionFormText() {},
  },
});

describe('DiffFileDiscussions', () => {
  let wrapper;
  let store;

  const oldPath = 'file.js';
  const newPath = 'file.js';

  const createFileDiscussion = () => ({
    id: 'file-disc-1',
    diff_discussion: true,
    position: {
      old_path: oldPath,
      new_path: newPath,
      position_type: 'file',
      old_line: null,
      new_line: null,
    },
    notes: [{ id: 'note-1', author: { id: 1 }, created_at: new Date().toISOString() }],
  });

  const createFileForm = () => ({
    id: 'form-1',
    diff_discussion: true,
    position: {
      old_path: oldPath,
      new_path: newPath,
      position_type: 'file',
      old_line: null,
      new_line: null,
    },
    isForm: true,
    noteBody: '',
  });

  const createComponent = () => {
    wrapper = shallowMount(DiffFileDiscussions, {
      provide: {
        store,
        userPermissions: { can_create_note: true },
        filePaths: { oldPath, newPath },
      },
    });
  };

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useMockStore();
  });

  it('renders existing discussions', () => {
    store.discussions = [createFileDiscussion()];
    createComponent();
    const discussions = wrapper.findComponent(DiffDiscussions).props('discussions');
    expect(discussions).toHaveLength(1);
    expect(discussions[0].id).toBe('file-disc-1');
  });

  it('renders expansion component for collapsed (hidden) file discussions', () => {
    store.setInitialDiscussions([{ ...createFileDiscussion(), hidden: true }]);
    createComponent();
    expect(wrapper.findComponent(DiffFileDiscussionExpansion).exists()).toBe(true);
    expect(wrapper.findComponent(DiffDiscussions).exists()).toBe(false);
  });

  it('expands hidden file discussions on toggle', async () => {
    store.setInitialDiscussions([{ ...createFileDiscussion(), hidden: true }]);
    createComponent();
    wrapper.findComponent(DiffFileDiscussionExpansion).vm.$emit('toggle');
    await nextTick();
    expect(wrapper.findComponent(DiffDiscussions).exists()).toBe(true);
    expect(wrapper.findComponent(DiffFileDiscussionExpansion).exists()).toBe(false);
  });

  it('renders NoteForm when a file discussion form exists', () => {
    store.discussions = [createFileForm()];
    createComponent();
    expect(wrapper.findComponent(NoteForm).exists()).toBe(true);
  });

  it('emits empty when discussions become empty', async () => {
    store.discussions = [createFileForm()];
    createComponent();
    store.discussions = [];
    await nextTick();
    expect(wrapper.emitted('empty')).toStrictEqual([[]]);
  });

  it('delegates note saving to store.createFileDiscussion', async () => {
    const form = createFileForm();
    store.discussions = [form];
    createComponent();
    await wrapper.findComponent(NoteForm).props('saveNote')('my comment');
    expect(store.createFileDiscussion).toHaveBeenCalledWith(form, 'my comment');
  });

  describe('draft notes', () => {
    const createDraftDiscussion = () => ({
      id: 'draft_1',
      isDraft: true,
      draft: { id: 'draft-1', author: { id: 1 }, created_at: new Date().toISOString() },
      diff_discussion: true,
      position: {
        old_path: oldPath,
        new_path: newPath,
        position_type: 'file',
      },
    });

    it('renders draft notes', () => {
      store.discussions = [createDraftDiscussion()];
      createComponent();
      expect(wrapper.findComponent(DraftNote).exists()).toBe(true);
    });

    it('always shows drafts even when regular discussions are hidden', () => {
      store.setInitialDiscussions([
        { ...createFileDiscussion(), hidden: true },
        createDraftDiscussion(),
      ]);
      createComponent();
      expect(wrapper.findComponent(DraftNote).exists()).toBe(true);
    });

    it('does not include drafts in collapsed discussions count', () => {
      store.setInitialDiscussions([createDraftDiscussion()]);
      createComponent();
      expect(wrapper.findComponent(DiffFileDiscussionExpansion).exists()).toBe(false);
    });
  });

  describe('draft review support', () => {
    describe('when store has createDraftFileDiscussion', () => {
      beforeEach(() => {
        store.createDraftFileDiscussion = jest.fn().mockResolvedValue();
        store.hasDrafts = false;
      });

      it('passes saveDraft to NoteForm', () => {
        store.discussions = [createFileForm()];
        createComponent();
        expect(wrapper.findComponent(NoteForm).props('saveDraft')).toEqual(expect.any(Function));
      });

      it('passes hasDrafts to NoteForm', () => {
        store.hasDrafts = true;
        store.discussions = [createFileForm()];
        createComponent();
        expect(wrapper.findComponent(NoteForm).props('hasDrafts')).toBe(true);
      });

      it('calls store.createDraftFileDiscussion on saveDraft', async () => {
        const form = createFileForm();
        store.discussions = [form];
        createComponent();
        await wrapper.findComponent(NoteForm).props('saveDraft')('draft comment');
        expect(store.createDraftFileDiscussion).toHaveBeenCalledWith(form, 'draft comment');
      });
    });

    describe('when store does not have createDraftFileDiscussion', () => {
      it('does not pass saveDraft to NoteForm', () => {
        store.discussions = [createFileForm()];
        createComponent();
        expect(wrapper.findComponent(NoteForm).props('saveDraft')).toBeNull();
      });
    });
  });

  describe('expand discussion for linked note fragment', () => {
    it('expands collapsed file discussions when hash matches a note', () => {
      setWindowLocation('https://example.com/diffs#note_100');
      const disc = {
        ...createFileDiscussion(),
        hidden: true,
        notes: [{ id: 100, author: { id: 1 }, created_at: new Date().toISOString() }],
      };
      store.setInitialDiscussions([disc]);
      createComponent();
      expect(store.discussions[0].hidden).toBe(false);
    });

    it('does not expand when hash does not match any note', () => {
      setWindowLocation('https://example.com/diffs#note_999');
      store.setInitialDiscussions([{ ...createFileDiscussion(), hidden: true }]);
      createComponent();
      expect(store.discussions[0].hidden).toBe(true);
    });

    it('does not expand when there is no note hash', () => {
      setWindowLocation('https://example.com/diffs');
      store.setInitialDiscussions([{ ...createFileDiscussion(), hidden: true }]);
      createComponent();
      expect(store.discussions[0].hidden).toBe(true);
    });
  });
});
