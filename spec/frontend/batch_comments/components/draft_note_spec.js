import { getByRole } from '@testing-library/dom';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import { createStore } from '~/batch_comments/stores';
import NoteableNote from '~/notes/components/noteable_note.vue';
import '~/behaviors/markdown/render_gfm';
import { createDraft } from '../mock_data';

const localVue = createLocalVue();

const NoteableNoteStub = stubComponent(NoteableNote, {
  template: `
    <div>
      <slot name="note-header-info">Test</slot>
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

  const getList = () => getByRole(wrapper.element, 'list');

  const createComponent = (propsData = { draft }) => {
    wrapper = shallowMount(localVue.extend(DraftNote), {
      store,
      propsData,
      localVue,
      stubs: {
        NoteableNote: NoteableNoteStub,
      },
    });

    jest.spyOn(wrapper.vm.$store, 'dispatch').mockImplementation();
  };

  beforeEach(() => {
    store = createStore();
    draft = createDraft();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders template', () => {
    createComponent();
    expect(wrapper.find('.draft-pending-label').exists()).toBe(true);

    const note = wrapper.find(NoteableNote);

    expect(note.exists()).toBe(true);
    expect(note.props().note).toEqual(draft);
  });

  describe('add comment now', () => {
    it('dispatches publishSingleDraft when clicking', () => {
      createComponent();
      const publishNowButton = wrapper.find({ ref: 'publishNowButton' });
      publishNowButton.vm.$emit('click');

      expect(wrapper.vm.$store.dispatch).toHaveBeenCalledWith(
        'batchComments/publishSingleDraft',
        1,
      );
    });

    it('sets as loading when draft is publishing', (done) => {
      createComponent();
      wrapper.vm.$store.state.batchComments.currentlyPublishingDrafts.push(1);

      wrapper.vm.$nextTick(() => {
        const publishNowButton = wrapper.find({ ref: 'publishNowButton' });

        expect(publishNowButton.props().loading).toBe(true);

        done();
      });
    });
  });

  describe('update', () => {
    it('dispatches updateDraft', (done) => {
      createComponent();
      const note = wrapper.find(NoteableNote);

      note.vm.$emit('handleEdit');

      wrapper.vm
        .$nextTick()
        .then(() => {
          const formData = {
            note: draft,
            noteText: 'a',
            resolveDiscussion: false,
          };

          note.vm.$emit('handleUpdateNote', formData);

          expect(wrapper.vm.$store.dispatch).toHaveBeenCalledWith(
            'batchComments/updateDraft',
            formData,
          );
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('deleteDraft', () => {
    it('dispatches deleteDraft', () => {
      createComponent();
      jest.spyOn(window, 'confirm').mockImplementation(() => true);

      const note = wrapper.find(NoteableNote);

      note.vm.$emit('handleDeleteNote', draft);

      expect(wrapper.vm.$store.dispatch).toHaveBeenCalledWith('batchComments/deleteDraft', draft);
    });
  });

  describe('quick actions', () => {
    it('renders referenced commands', (done) => {
      createComponent();
      wrapper.setProps({
        draft: {
          ...draft,
          references: {
            commands: 'test command',
          },
        },
      });

      wrapper.vm.$nextTick(() => {
        const referencedCommands = wrapper.find('.referenced-commands');

        expect(referencedCommands.exists()).toBe(true);
        expect(referencedCommands.text()).toContain('test command');

        done();
      });
    });
  });

  describe('multiline comments', () => {
    describe.each`
      desc                          | props                 | event           | expectedCalls
      ${'with `draft.position`'}    | ${draftWithLineRange} | ${'mouseenter'} | ${[['setSelectedCommentPositionHover', LINE_RANGE]]}
      ${'with `draft.position`'}    | ${draftWithLineRange} | ${'mouseleave'} | ${[['setSelectedCommentPositionHover']]}
      ${'without `draft.position`'} | ${{}}                 | ${'mouseenter'} | ${[]}
      ${'without `draft.position`'} | ${{}}                 | ${'mouseleave'} | ${[]}
    `('$desc', ({ props, event, expectedCalls }) => {
      beforeEach(() => {
        createComponent({ draft: { ...draft, ...props } });
        jest.spyOn(store, 'dispatch');
      });

      it(`calls store ${expectedCalls.length} times on ${event}`, () => {
        getList().dispatchEvent(new MouseEvent(event, { bubbles: true }));
        expect(store.dispatch.mock.calls).toEqual(expectedCalls);
      });
    });
  });
});
