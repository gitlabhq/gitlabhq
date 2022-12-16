import { nextTick } from 'vue';
import { GlButton, GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import PublishButton from '~/batch_comments/components/publish_button.vue';
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

  const findSubmitReviewButton = () => wrapper.findComponent(PublishButton);
  const findAddCommentButton = () => wrapper.findComponent(GlButton);

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
    expect(wrapper.findComponent(GlBadge).exists()).toBe(true);

    const note = wrapper.findComponent(NoteableNote);

    expect(note.exists()).toBe(true);
    expect(note.props().note).toEqual(draft);
  });

  describe('add comment now', () => {
    it('dispatches publishSingleDraft when clicking', () => {
      createComponent();
      const publishNowButton = findAddCommentButton();
      publishNowButton.vm.$emit('click');

      expect(wrapper.vm.$store.dispatch).toHaveBeenCalledWith(
        'batchComments/publishSingleDraft',
        1,
      );
    });

    it('sets as loading when draft is publishing', async () => {
      createComponent();
      wrapper.vm.$store.state.batchComments.currentlyPublishingDrafts.push(1);

      await nextTick();
      const publishNowButton = findAddCommentButton();

      expect(publishNowButton.props().loading).toBe(true);
    });

    it('sets as disabled when review is publishing', async () => {
      createComponent();
      wrapper.vm.$store.state.batchComments.isPublishing = true;

      await nextTick();
      const publishNowButton = findAddCommentButton();

      expect(publishNowButton.props().disabled).toBe(true);
      expect(publishNowButton.props().loading).toBe(false);
    });

    it('hides button when mr_review_submit_comment is enabled', () => {
      createComponent({ draft }, { mrReviewSubmitComment: true });

      expect(findAddCommentButton().exists()).toBe(false);
    });
  });

  describe('submit review', () => {
    it('sets as disabled when draft is publishing', async () => {
      createComponent();
      wrapper.vm.$store.state.batchComments.currentlyPublishingDrafts.push(1);

      await nextTick();
      const publishNowButton = findSubmitReviewButton();

      expect(publishNowButton.attributes().disabled).toBe('true');
    });
  });

  describe('update', () => {
    it('dispatches updateDraft', async () => {
      createComponent();
      const note = wrapper.findComponent(NoteableNote);

      note.vm.$emit('handleEdit');

      await nextTick();
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
    });
  });

  describe('deleteDraft', () => {
    it('dispatches deleteDraft', () => {
      createComponent();
      jest.spyOn(window, 'confirm').mockImplementation(() => true);

      const note = wrapper.findComponent(NoteableNote);

      note.vm.$emit('handleDeleteNote', draft);

      expect(wrapper.vm.$store.dispatch).toHaveBeenCalledWith('batchComments/deleteDraft', draft);
    });
  });

  describe('quick actions', () => {
    it('renders referenced commands', async () => {
      createComponent();
      wrapper.setProps({
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
        wrapper.element.dispatchEvent(new MouseEvent(event, { bubbles: true }));
        expect(store.dispatch.mock.calls).toEqual(expectedCalls);
      });
    });
  });
});
