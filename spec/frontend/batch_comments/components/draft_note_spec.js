import { shallowMount, createLocalVue } from '@vue/test-utils';
import { getByRole } from '@testing-library/dom';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import { createStore } from '~/batch_comments/stores';
import NoteableNote from '~/notes/components/noteable_note.vue';
import '~/behaviors/markdown/render_gfm';
import { createDraft } from '../mock_data';

const localVue = createLocalVue();

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

  const createComponent = (propsData = { draft }, features = {}) => {
    wrapper = shallowMount(localVue.extend(DraftNote), {
      store,
      propsData,
      localVue,
      provide: {
        glFeatures: { multilineComments: true, ...features },
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

    it('sets as loading when draft is publishing', done => {
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
    it('dispatches updateDraft', done => {
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
    it('renders referenced commands', done => {
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
      desc                          | props                 | features                        | event           | expectedCalls
      ${'with `draft.position`'}    | ${draftWithLineRange} | ${{}}                           | ${'mouseenter'} | ${[['setSelectedCommentPositionHover', LINE_RANGE]]}
      ${'with `draft.position`'}    | ${draftWithLineRange} | ${{}}                           | ${'mouseleave'} | ${[['setSelectedCommentPositionHover']]}
      ${'with `draft.position`'}    | ${draftWithLineRange} | ${{ multilineComments: false }} | ${'mouseenter'} | ${[]}
      ${'with `draft.position`'}    | ${draftWithLineRange} | ${{ multilineComments: false }} | ${'mouseleave'} | ${[]}
      ${'without `draft.position`'} | ${{}}                 | ${{}}                           | ${'mouseenter'} | ${[]}
      ${'without `draft.position`'} | ${{}}                 | ${{}}                           | ${'mouseleave'} | ${[]}
    `('$desc and features $features', ({ props, event, features, expectedCalls }) => {
      beforeEach(() => {
        createComponent({ draft: { ...draft, ...props } }, features);
        jest.spyOn(store, 'dispatch');
      });

      it(`calls store ${expectedCalls.length} times on ${event}`, () => {
        getList().dispatchEvent(new MouseEvent(event, { bubbles: true }));
        expect(store.dispatch.mock.calls).toEqual(expectedCalls);
      });
    });
  });
});
