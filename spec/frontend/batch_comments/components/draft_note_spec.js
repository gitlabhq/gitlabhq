import { shallowMount, createLocalVue } from '@vue/test-utils';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import { createStore } from '~/batch_comments/stores';
import NoteableNote from '~/notes/components/noteable_note.vue';
import '~/behaviors/markdown/render_gfm';
import { createDraft } from '../mock_data';

const localVue = createLocalVue();

describe('Batch comments draft note component', () => {
  let wrapper;
  let draft;

  beforeEach(() => {
    const store = createStore();

    draft = createDraft();

    wrapper = shallowMount(localVue.extend(DraftNote), {
      store,
      propsData: { draft },
      localVue,
    });

    jest.spyOn(wrapper.vm.$store, 'dispatch').mockImplementation();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders template', () => {
    expect(wrapper.find('.draft-pending-label').exists()).toBe(true);

    const note = wrapper.find(NoteableNote);

    expect(note.exists()).toBe(true);
    expect(note.props().note).toEqual(draft);
  });

  describe('add comment now', () => {
    it('dispatches publishSingleDraft when clicking', () => {
      const publishNowButton = wrapper.find({ ref: 'publishNowButton' });
      publishNowButton.vm.$emit('click');

      expect(wrapper.vm.$store.dispatch).toHaveBeenCalledWith(
        'batchComments/publishSingleDraft',
        1,
      );
    });

    it('sets as loading when draft is publishing', done => {
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
      jest.spyOn(window, 'confirm').mockImplementation(() => true);

      const note = wrapper.find(NoteableNote);

      note.vm.$emit('handleDeleteNote', draft);

      expect(wrapper.vm.$store.dispatch).toHaveBeenCalledWith('batchComments/deleteDraft', draft);
    });
  });

  describe('quick actions', () => {
    it('renders referenced commands', done => {
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
});
