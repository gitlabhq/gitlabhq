import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { PiniaVuePlugin } from 'pinia';
import { createTestingPinia } from '@pinia/testing';
import DiffCommentCell from '~/diffs/components/diff_comment_cell.vue';
import DiffDiscussionReply from '~/diffs/components/diff_discussion_reply.vue';
import DiffDiscussions from '~/diffs/components/diff_discussions.vue';
import DiffLineNoteForm from '~/diffs/components/diff_line_note_form.vue';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { globalAccessorPlugin } from '~/pinia/plugins';

Vue.use(PiniaVuePlugin);

describe('DiffCommentCell', () => {
  let wrapper;
  let pinia;

  const createComponent = (props = {}) => {
    const { renderDiscussion, ...otherProps } = props;
    const line = {
      discussions: [],
      renderDiscussion,
    };
    const diffFileHash = 'abc';

    wrapper = shallowMount(DiffCommentCell, {
      pinia,
      propsData: { line, diffFileHash, ...otherProps },
    });
  };

  const findDiffDiscussions = () => wrapper.findComponent(DiffDiscussions);
  const findDiffDiscussionReply = () => wrapper.findComponent(DiffDiscussionReply);
  const findDiffLineNoteForm = () => findDiffDiscussionReply().findComponent(DiffLineNoteForm);

  beforeEach(() => {
    pinia = createTestingPinia({ plugins: [globalAccessorPlugin] });
    useLegacyDiffs();
    useNotes();
  });

  it('renders discussions if line has discussions', () => {
    createComponent({ renderDiscussion: true });

    expect(findDiffDiscussions().exists()).toBe(true);
  });

  it('does not render discussions if line has no discussions', () => {
    createComponent();

    expect(findDiffDiscussions().exists()).toBe(false);
  });

  describe('when archived', () => {
    beforeEach(() => {
      useNotes().noteableData = { archived: true };

      createComponent();
    });

    it('does not render discussion reply', () => {
      expect(findDiffDiscussionReply().exists()).toBe(false);
    });
  });

  describe('when not archived', () => {
    beforeEach(() => {
      useNotes().noteableData = { archived: false };
    });

    describe('when has no draft', () => {
      it('renders discussion reply with form', () => {
        createComponent({ hasDraft: false });

        expect(findDiffDiscussionReply().exists()).toBe(true);
      });

      describe('when line has comment form', () => {
        it('renders diff line note form', () => {
          createComponent({ hasDraft: false, line: { discussions: [], hasCommentForm: true } });

          expect(findDiffLineNoteForm().exists()).toBe(true);
        });
      });

      describe('when line has no comment form', () => {
        it('renders diff line note form', () => {
          createComponent({ hasDraft: false, line: { discussions: [], hasCommentForm: false } });

          expect(findDiffLineNoteForm().exists()).toBe(false);
        });
      });
    });

    describe('when has draft', () => {
      it('does not render discussion reply', () => {
        createComponent({ hasDraft: true });

        expect(findDiffDiscussionReply().exists()).toBe(false);
      });
    });
  });
});
