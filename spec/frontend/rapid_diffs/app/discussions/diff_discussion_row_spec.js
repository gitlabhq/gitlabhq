import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { defineStore } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import setWindowLocation from 'helpers/set_window_location_helper';
import DiffDiscussionRow from '~/rapid_diffs/app/discussions/diff_discussion_row.vue';
import DiffGutterToggle from '~/rapid_diffs/app/discussions/diff_gutter_toggle.vue';
import DiffLineDiscussions from '~/rapid_diffs/app/discussions/diff_line_discussions.vue';

const useMockStore = defineStore('discussionRowTestStore', {
  state: () => ({
    discussions: [],
  }),
  actions: {
    findLineDiscussionsForPosition() {
      return this.discussions;
    },
    setPositionDiscussionsHidden() {},
    addNewLineDiscussionForm() {},
  },
});

describe('DiffDiscussionRow', () => {
  let wrapper;
  let store;

  const oldPath = 'file.js';
  const newPath = 'file.js';

  const createDiscussion = (overrides = {}) => ({
    id: '1',
    diff_discussion: true,
    hidden: false,
    position: { old_path: oldPath, new_path: newPath, old_line: 5, new_line: null },
    notes: [{ id: 'note-1', author: { id: 1 } }],
    ...overrides,
  });

  const createDraft = (overrides = {}) => ({
    id: 'draft_1',
    isDraft: true,
    draft: { id: 'draft-1', author: { id: 1 } },
    diff_discussion: true,
    position: { old_path: oldPath, new_path: newPath, old_line: 5, new_line: null },
    ...overrides,
  });

  const createComponent = (props = {}) => {
    wrapper = shallowMount(DiffDiscussionRow, {
      propsData: {
        oldLine: 5,
        newLine: null,
        parallel: false,
        ...props,
      },
      provide: { store, filePaths: { oldPath, newPath } },
    });
  };

  const findCells = () => wrapper.findAll('td');
  const findDiscussions = () => wrapper.findAllComponents(DiffLineDiscussions);
  const findGutterToggles = () => wrapper.findAllComponents(DiffGutterToggle);

  beforeEach(() => {
    createTestingPinia({ stubActions: false });
    store = useMockStore();
  });

  describe('inline view', () => {
    it('renders one cell with colspan 3', () => {
      store.discussions = [createDiscussion()];
      createComponent();
      expect(findCells()).toHaveLength(1);
      expect(findCells().at(0).attributes('colspan')).toBe('3');
    });

    it('passes visible discussions to DiffLineDiscussions', () => {
      store.discussions = [createDiscussion()];
      createComponent();
      expect(findDiscussions().at(0).props('discussions')).toHaveLength(1);
    });
  });

  describe('parallel view', () => {
    it('renders two cells with colspan 2 for side-specific discussions', () => {
      store.discussions = [createDiscussion()];
      createComponent({ parallel: true, oldLine: 5, newLine: null });
      expect(findCells()).toHaveLength(2);
      expect(findCells().at(0).attributes('colspan')).toBe('2');
      expect(findCells().at(1).attributes('colspan')).toBe('2');
    });

    it('renders one cell with colspan 4 for spanning discussions', () => {
      store.discussions = [
        createDiscussion({
          position: { old_path: oldPath, new_path: newPath, old_line: 5, new_line: 3 },
        }),
      ];
      createComponent({ parallel: true, oldLine: 5, newLine: 3 });
      expect(findCells()).toHaveLength(1);
      expect(findCells().at(0).attributes('colspan')).toBe('4');
    });

    it('renders two cells with colspan 2 for changed row even when both lines are set', () => {
      store.discussions = [createDiscussion()];
      createComponent({ parallel: true, oldLine: 5, newLine: 3, changed: true });
      expect(findCells()).toHaveLength(2);
      expect(findCells().at(0).attributes('colspan')).toBe('2');
      expect(findCells().at(1).attributes('colspan')).toBe('2');
    });

    it('calls setPositionDiscussionsHidden for all positions on spanning row toggle', () => {
      store.discussions = [
        createDiscussion({
          position: { old_path: oldPath, new_path: newPath, old_line: 5, new_line: 3 },
        }),
      ];
      createComponent({ parallel: true, oldLine: 5, newLine: 3 });
      findGutterToggles().at(0).vm.$emit('toggle', true);
      expect(store.setPositionDiscussionsHidden).toHaveBeenCalledWith(
        { oldPath, newPath, oldLine: 5, newLine: 3 },
        true,
      );
    });
  });

  describe('collapsed state', () => {
    it('passes expanded true to gutter toggle when not all hidden', () => {
      store.discussions = [createDiscussion()];
      createComponent();
      expect(findGutterToggles().at(0).props('expanded')).toBe(true);
    });

    it('passes expanded false to gutter toggle when all hidden', () => {
      store.discussions = [createDiscussion({ hidden: true })];
      createComponent();
      expect(findGutterToggles().at(0).props('expanded')).toBe(false);
    });

    it('collapses when all discussions are hidden', () => {
      store.discussions = [createDiscussion({ hidden: true })];
      createComponent();
      expect(wrapper.find('tr').attributes('data-collapsed')).toBe('');
      expect(findDiscussions()).toHaveLength(0);
    });

    it('does not collapse when at least one discussion is not hidden', () => {
      store.discussions = [
        createDiscussion({ hidden: true }),
        createDiscussion({
          id: '2',
          hidden: false,
          position: { old_path: oldPath, new_path: newPath, old_line: 5, new_line: null },
        }),
      ];
      createComponent();
      expect(wrapper.find('tr').attributes('data-collapsed')).toBeUndefined();
    });

    it('shows all discussions when not collapsed', () => {
      store.discussions = [
        createDiscussion({ hidden: true }),
        createDiscussion({
          id: '2',
          hidden: false,
          position: { old_path: oldPath, new_path: newPath, old_line: 5, new_line: null },
        }),
      ];
      createComponent();
      expect(findDiscussions().at(0).props('discussions')).toHaveLength(2);
    });

    it('calls setPositionDiscussionsHidden on manual toggle via gutter', () => {
      store.discussions = [createDiscussion()];
      createComponent();
      findGutterToggles().at(0).vm.$emit('toggle', true);
      expect(store.setPositionDiscussionsHidden).toHaveBeenCalledWith(
        { oldPath, newPath, oldLine: 5, newLine: null },
        true,
      );
    });
  });

  describe('resolve-driven collapse', () => {
    it('hides all discussions when last one is resolved', async () => {
      store.discussions = [createDiscussion({ resolvable: true, resolved: false })];
      createComponent();
      store.discussions[0].resolved = true;
      await nextTick();
      expect(store.setPositionDiscussionsHidden).toHaveBeenCalledWith(
        { oldPath, newPath, oldLine: 5, newLine: null },
        true,
      );
    });

    it('unhides all discussions when one is unresolved', async () => {
      store.discussions = [createDiscussion({ resolvable: true, resolved: true })];
      createComponent();
      store.discussions[0].resolved = false;
      await nextTick();
      expect(store.setPositionDiscussionsHidden).toHaveBeenCalledWith(
        { oldPath, newPath, oldLine: 5, newLine: null },
        false,
      );
    });

    it('hides when all discussions at position are resolved', async () => {
      store.discussions = [
        createDiscussion({ resolvable: true, resolved: false }),
        createDiscussion({
          id: '2',
          resolvable: true,
          resolved: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 5, new_line: null },
        }),
      ];
      createComponent();
      store.discussions[0].resolved = true;
      await nextTick();
      expect(store.setPositionDiscussionsHidden).toHaveBeenCalledWith(
        { oldPath, newPath, oldLine: 5, newLine: null },
        true,
      );
    });
  });

  describe('parallel collapsed state', () => {
    it('does not collapse when only one side has all discussions hidden', () => {
      store.discussions = [
        createDiscussion({
          hidden: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 5, new_line: null },
        }),
        createDiscussion({
          id: '2',
          hidden: false,
          position: { old_path: oldPath, new_path: newPath, old_line: null, new_line: 3 },
        }),
      ];
      createComponent({ parallel: true, oldLine: 5, newLine: 3, changed: true });
      expect(wrapper.find('tr').attributes('data-collapsed')).toBeUndefined();
    });

    it('passes expanded true to both gutter toggles when one side is hidden but the other is not', () => {
      store.discussions = [
        createDiscussion({
          hidden: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 5, new_line: null },
        }),
        createDiscussion({
          id: '2',
          hidden: false,
          position: { old_path: oldPath, new_path: newPath, old_line: null, new_line: 3 },
        }),
      ];
      createComponent({ parallel: true, oldLine: 5, newLine: 3, changed: true });
      expect(findGutterToggles().at(0).props('expanded')).toBe(true);
      expect(findGutterToggles().at(1).props('expanded')).toBe(true);
    });

    it('collapses when only one side has discussions and they are all hidden', () => {
      store.discussions = [
        createDiscussion({
          hidden: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 5, new_line: null },
        }),
      ];
      createComponent({ parallel: true, oldLine: 5, newLine: 3, changed: true });
      expect(wrapper.find('tr').attributes('data-collapsed')).toBe('');
    });

    it('auto-collapses one-sided discussions when all are resolved', async () => {
      store.discussions = [
        createDiscussion({
          resolvable: true,
          resolved: false,
          position: { old_path: oldPath, new_path: newPath, old_line: 5, new_line: null },
        }),
      ];
      createComponent({ parallel: true, oldLine: 5, newLine: 3, changed: true });
      store.discussions[0].resolved = true;
      await nextTick();
      expect(store.setPositionDiscussionsHidden).toHaveBeenCalledWith(
        { oldPath, newPath, oldLine: 5, newLine: null },
        true,
      );
      expect(store.setPositionDiscussionsHidden).toHaveBeenCalledWith(
        { oldPath, newPath, oldLine: null, newLine: 3 },
        true,
      );
    });

    it('collapses when both sides have all discussions hidden', () => {
      store.discussions = [
        createDiscussion({
          hidden: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 5, new_line: null },
        }),
        createDiscussion({
          id: '2',
          hidden: true,
          position: { old_path: oldPath, new_path: newPath, old_line: null, new_line: 3 },
        }),
      ];
      createComponent({ parallel: true, oldLine: 5, newLine: 3, changed: true });
      expect(wrapper.find('tr').attributes('data-collapsed')).toBe('');
    });
  });

  describe('draft notes behaviour', () => {
    it('excludes drafts from gutter toggle discussions', () => {
      store.discussions = [createDiscussion(), createDraft()];
      createComponent();
      const gutterDiscussions = findGutterToggles().at(0).props('discussions');
      expect(gutterDiscussions).toHaveLength(1);
      expect(gutterDiscussions[0].isDraft).toBeUndefined();
    });

    it('keeps drafts visible when all regular discussions are hidden', () => {
      store.discussions = [createDiscussion({ hidden: true }), createDraft()];
      createComponent();
      expect(findDiscussions()).toHaveLength(1);
      expect(findDiscussions().at(0).props('discussions')).toEqual([
        expect.objectContaining({ isDraft: true }),
      ]);
    });

    it('passes collapsed true when all regular discussions are hidden and drafts exist', () => {
      store.discussions = [createDiscussion({ hidden: true }), createDraft()];
      createComponent();
      expect(findDiscussions().at(0).props('collapsed')).toBe(true);
    });

    it('does not set data-collapsed when drafts are present even if regular discussions are hidden', () => {
      store.discussions = [createDiscussion({ hidden: true }), createDraft()];
      createComponent();
      expect(wrapper.find('tr').attributes('data-collapsed')).toBeUndefined();
    });

    it('does not block resolve-driven collapse when drafts are present', async () => {
      store.discussions = [createDiscussion({ resolvable: true, resolved: false }), createDraft()];
      createComponent();
      store.discussions[0].resolved = true;
      await nextTick();
      expect(store.setPositionDiscussionsHidden).toHaveBeenCalledWith(
        { oldPath, newPath, oldLine: 5, newLine: null },
        true,
      );
    });

    it('allows collapsing in parallel view when one side has only drafts', () => {
      store.discussions = [
        createDiscussion({
          hidden: true,
          position: { old_path: oldPath, new_path: newPath, old_line: 5, new_line: null },
        }),
        createDraft({
          position: { old_path: oldPath, new_path: newPath, old_line: null, new_line: 3 },
        }),
      ];
      createComponent({ parallel: true, oldLine: 5, newLine: 3, changed: true });
      expect(findGutterToggles().at(0).props('expanded')).toBe(false);
    });
  });

  it('emits start-thread with position when DiffLineDiscussions emits start-thread', () => {
    store.discussions = [createDiscussion()];
    createComponent();
    findDiscussions().at(0).vm.$emit('start-thread');
    expect(wrapper.emitted('start-thread')).toStrictEqual([
      [{ oldPath, newPath, oldLine: 5, newLine: null }],
    ]);
  });

  it('emits empty when all discussions are removed', async () => {
    store.discussions = [createDiscussion()];
    createComponent();
    store.discussions = [];
    await nextTick();
    expect(wrapper.emitted('empty')).toStrictEqual([[]]);
  });

  describe('expandDiscussionForNoteFragment', () => {
    it('expands collapsed discussions when hash matches a note', () => {
      setWindowLocation('https://example.com/diffs#note_100');
      store.discussions = [
        createDiscussion({ hidden: true, notes: [{ id: 100, author: { id: 1 } }] }),
      ];
      createComponent();
      expect(store.setPositionDiscussionsHidden).toHaveBeenCalledWith(
        { oldPath, newPath, oldLine: 5, newLine: null },
        false,
      );
    });

    it('does not expand when hash does not match any note', () => {
      setWindowLocation('https://example.com/diffs#note_999');
      store.discussions = [createDiscussion({ hidden: true })];
      createComponent();
      expect(store.setPositionDiscussionsHidden).not.toHaveBeenCalledWith(expect.anything(), false);
    });

    it('does not expand when there is no note hash', () => {
      setWindowLocation('https://example.com/diffs#diff_abc');
      store.discussions = [createDiscussion({ hidden: true })];
      createComponent();
      expect(store.setPositionDiscussionsHidden).not.toHaveBeenCalledWith(expect.anything(), false);
    });
  });
});
