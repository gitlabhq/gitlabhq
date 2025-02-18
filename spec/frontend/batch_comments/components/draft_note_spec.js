import { nextTick } from 'vue';
import { GlBadge } from '@gitlab/ui';
import { createTestingPinia } from '@pinia/testing';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import { createStore } from '~/batch_comments/stores';
import NoteableNote from '~/notes/components/noteable_note.vue';
import { clearDraft } from '~/lib/utils/autosave';
import * as types from '~/batch_comments/stores/modules/batch_comments/mutation_types';
import { useNotes } from '~/notes/store/legacy_notes';
import { globalAccessorPlugin } from '~/pinia/plugins';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useBatchComments } from '~/batch_comments/store';
import { createDraft } from '../mock_data';

jest.mock('~/behaviors/markdown/render_gfm');
jest.mock('~/lib/utils/autosave');

const NoteableNoteStub = stubComponent(NoteableNote, {
  template: `
    <div>
      <slot name="note-header-info">Test</slot>
      <slot name="after-note-body">Test</slot>
    </div>
  `,
});

describe('Batch comments draft note component', () => {
  let store;
  let wrapper;
  let draft;
  const LINE_RANGE = {};
  const draftWithLineRange = {
    position: {
      line_range: LINE_RANGE,
    },
  };

  const createComponent = (propsData = { draft }, glFeatures = {}) => {
    wrapper = shallowMount(DraftNote, {
      store,
      propsData,
      stubs: {
        NoteableNote: NoteableNoteStub,
      },
      provide: {
        glFeatures,
      },
    });

    jest.spyOn(store, 'dispatch').mockImplementation();
    jest.spyOn(store, 'commit').mockImplementation();
  };

  const findNoteableNote = () => wrapper.findComponent(NoteableNote);

  beforeEach(() => {
    createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
    store = createStore();
    draft = createDraft();
  });

  it('renders template', () => {
    const autosaveKey = 'autosave';
    createComponent({ draft, autosaveKey });
    expect(wrapper.findComponent(GlBadge).exists()).toBe(true);

    expect(findNoteableNote().exists()).toBe(true);
    expect(findNoteableNote().props('note')).toEqual(draft);
    expect(findNoteableNote().props('autosaveKey')).toEqual(
      `${autosaveKey}/draft-note-${draft.id}`,
    );
  });

  describe('update', () => {
    it('dispatches updateDraft', async () => {
      createComponent();
      findNoteableNote().vm.$emit('handleEdit');

      await nextTick();
      const formData = {
        note: draft,
        noteText: 'a',
        resolveDiscussion: false,
        callback: jest.fn(),
        parentElement: wrapper.vm.$el,
        errorCallback: jest.fn(),
      };

      findNoteableNote().vm.$emit('handleUpdateNote', formData);

      expect(useBatchComments().updateDraft).toHaveBeenCalledWith(formData);
    });
  });

  describe('deleteDraft', () => {
    it('dispatches deleteDraft', () => {
      createComponent();
      jest.spyOn(window, 'confirm').mockImplementation(() => true);

      findNoteableNote().vm.$emit('handleDeleteNote', draft);

      expect(useBatchComments().deleteDraft).toHaveBeenCalledWith(draft);
    });
  });

  describe('quick actions', () => {
    it('renders referenced commands', async () => {
      createComponent({
        draft: {
          ...draft,
          references: {
            commands: 'test command',
          },
        },
      });

      await nextTick();
      const referencedCommands = wrapper.find('.draft-note-referenced-commands');

      expect(referencedCommands.exists()).toBe(true);
      expect(referencedCommands.text()).toContain('test command');
    });
  });

  describe('multiline comments', () => {
    it(`calls store with draft.position with mouseenter`, () => {
      createComponent({ draft: { ...draft, ...draftWithLineRange } });
      findNoteableNote().trigger('mouseenter');

      expect(store.dispatch).toHaveBeenCalledWith('setSelectedCommentPositionHover', LINE_RANGE);
    });

    it(`calls store with draft.position and mouseleave`, () => {
      createComponent({ draft: { ...draft, ...draftWithLineRange } });
      findNoteableNote().trigger('mouseleave');

      expect(store.dispatch).toHaveBeenCalledWith('setSelectedCommentPositionHover');
    });

    it(`does not call store without draft position`, () => {
      createComponent({ draft });

      findNoteableNote().trigger('mouseenter');
      findNoteableNote().trigger('mouseleave');

      expect(store.dispatch).not.toHaveBeenCalled();
    });
  });

  describe('opened state', () => {
    it(`restores opened state`, () => {
      draft.isEditing = true;
      createComponent({ draft });
      expect(findNoteableNote().props('restoreFromAutosave')).toBe(true);
    });

    it(`sets opened state`, async () => {
      createComponent({ draft });
      await findNoteableNote().vm.$emit('handleEdit');
      expect(useBatchComments()[types.SET_DRAFT_EDITING]).toHaveBeenCalledWith({
        draftId: draft.id,
        isEditing: true,
      });
    });

    it(`resets opened state on form close`, async () => {
      draft.isEditing = true;
      createComponent({ draft });
      await findNoteableNote().vm.$emit('cancelForm');
      expect(findNoteableNote().props('restoreFromAutosave')).toBe(false);
      expect(useBatchComments()[types.SET_DRAFT_EDITING]).toHaveBeenCalledWith({
        draftId: draft.id,
        isEditing: false,
      });
    });

    it(`clears autosave key on form cancel`, () => {
      createComponent({ draft, autosaveKey: 'foo' });
      findNoteableNote().vm.$emit('cancelForm');
      expect(clearDraft).toHaveBeenCalledWith(`foo/draft-note-${draft.id}`);
    });
  });
});
