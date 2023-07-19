import { nextTick } from 'vue';
import { GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import { createStore } from '~/batch_comments/stores';
import NoteableNote from '~/notes/components/noteable_note.vue';
import { createDraft } from '../mock_data';

jest.mock('~/behaviors/markdown/render_gfm');

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
  };

  const findNoteableNote = () => wrapper.findComponent(NoteableNote);

  beforeEach(() => {
    store = createStore();
    draft = createDraft();
  });

  it('renders template', () => {
    createComponent();
    expect(wrapper.findComponent(GlBadge).exists()).toBe(true);

    expect(findNoteableNote().exists()).toBe(true);
    expect(findNoteableNote().props('note')).toEqual(draft);
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

      expect(store.dispatch).toHaveBeenCalledWith('batchComments/updateDraft', formData);
    });
  });

  describe('deleteDraft', () => {
    it('dispatches deleteDraft', () => {
      createComponent();
      jest.spyOn(window, 'confirm').mockImplementation(() => true);

      findNoteableNote().vm.$emit('handleDeleteNote', draft);

      expect(store.dispatch).toHaveBeenCalledWith('batchComments/deleteDraft', draft);
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
      const referencedCommands = wrapper.find('.referenced-commands');

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
});
