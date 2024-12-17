import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WikiDiscussion from '~/pages/shared/wikis/wiki_notes/components/wiki_discussion.vue';
import WikiNote from '~/pages/shared/wikis/wiki_notes/components/wiki_note.vue';
import PlaceholderNote from '~/pages/shared/wikis/wiki_notes/components/placeholder_note.vue';
import DiscussionReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import WikiDiscussionsSignedOut from '~/pages/shared/wikis/wiki_notes/components/wiki_discussions_signed_out.vue';
import WikiCommentForm from '~/pages/shared/wikis/wiki_notes/components/wiki_comment_form.vue';
import * as autosave from '~/lib/utils/autosave';
import { currentUserData, note, noteableId, noteableType } from '../mock_data';

describe('WikiDiscussion', () => {
  let wrapper;

  const createWrapper = ({ props, provideData = { userData: currentUserData } } = {}) =>
    shallowMountExtended(WikiDiscussion, {
      propsData: {
        discussion: [note],
        noteableId,
        ...props,
      },
      provide: {
        noteableType,
        currentUserData,
        ...provideData,
      },
    });

  const noteFooter = () => wrapper.findByTestId('wiki-note-footer');

  beforeEach(() => {
    wrapper = createWrapper();
  });

  describe('renders correctly', () => {
    it('should render wiki note correctly', () => {
      expect(wrapper.findComponent(WikiNote).props('note')).toMatchObject(note);
    });

    it('should not render note footer when there is no reply and replying is false', () => {
      // there is only one note in discussion array so there is no reply
      expect(wrapper.findByTestId('wiki-note-footer').exists()).toBe(false);
    });

    it('should render note footer when isReplying is true', async () => {
      wrapper.vm.toggleReplying(true);
      await nextTick();
      expect(wrapper.findByTestId('wiki-note-footer').exists()).toBe(true);
    });

    describe('when there are replies', () => {
      beforeEach(() => {
        wrapper = createWrapper({
          props: {
            discussion: [
              note,
              {
                ...note,
                body: 'another example note',
                bodyHtml: '<p data-sourcepos="1:1-1:29" dir="auto">another example note</p>',
              },
            ],
          },
        });
      });

      it("should set 'replyNote' prop to true when rendering replies", () => {
        expect(noteFooter().findComponent(WikiNote).props('replyNote')).toBe(true);
      });

      it('should render reply in note footer when there is at least 1 reply', () => {
        expect(noteFooter().findComponent(WikiNote).props('note')).toMatchObject({
          ...note,
          body: 'another example note',
          bodyHtml: '<p data-sourcepos="1:1-1:29" dir="auto">another example note</p>',
        });
      });

      it('should render placeholder correctly note when "placeholderNote" is set', async () => {
        wrapper.vm.setPlaceHolderNote({
          body: 'another example note',
        });
        await nextTick();

        const placeholderNote = noteFooter().findComponent(PlaceholderNote);
        expect(placeholderNote.props('note')).toStrictEqual({
          body: 'another example note',
        });
      });
    });
  });

  describe('when user is not signed in', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        props: { discussion: [note, note] },
        provideData: { currentUserData: null },
      });
    });

    it('should render wiki discussion signed out component', () => {
      expect(noteFooter().findComponent(WikiDiscussionsSignedOut).exists()).toBe(true);
    });

    it('should not render reply form placeholder', () => {
      expect(noteFooter().findComponent(DiscussionReplyPlaceholder).exists()).toBe(false);
    });

    it('should not render reply form', () => {
      expect(noteFooter().findComponent(WikiCommentForm).exists()).toBe(false);
    });
  });

  describe('component functions properly when user is signed in', () => {
    beforeEach(() => {
      wrapper = createWrapper({ props: { discussion: [note, note] } });
    });

    it('should call clearDraft whenever toggle reply is called with a value of false', () => {
      const clearDraftSpy = jest.spyOn(autosave, 'clearDraft');

      wrapper.vm.toggleReplying(false);

      expect(clearDraftSpy).toHaveBeenCalledTimes(1);
    });

    it('should not render wiki discussion signed out component', () => {
      expect(noteFooter().findComponent(WikiDiscussionsSignedOut).exists()).toBe(false);
    });

    it('should render reply form placeholder when isReplying is false', () => {
      // isReplying is set to false by default
      expect(noteFooter().findComponent(DiscussionReplyPlaceholder).exists()).toBe(true);
    });

    it('should render reply form when isReplying is true', async () => {
      wrapper.vm.toggleReplying(true);
      await nextTick();
      expect(Boolean(wrapper.vm.$refs.commentForm)).toBe(true);
    });

    it("should render replyForm when 'reply' event is fired from wiki note", async () => {
      const wikiNote = wrapper.findComponent(WikiNote);
      wikiNote.vm.$emit('reply');
      await nextTick();

      expect(Boolean(wrapper.vm.$refs.commentForm)).toBe(true);
    });

    it('should render reply form  when focus event is fired from discussion reply placeholder', async () => {
      const replyPlaceholder = wrapper.findComponent(DiscussionReplyPlaceholder);
      replyPlaceholder.vm.$emit('focus');

      await nextTick();
      expect(Boolean(wrapper.vm.$refs.commentForm)).toBe(true);
    });
  });

  describe('reply form', () => {
    let replyForm;
    beforeEach(async () => {
      wrapper.vm.toggleReplying(true);
      await nextTick();
      replyForm = wrapper.vm.$refs.commentForm;
    });

    it('should unrender relpyForm when cancel event is fired', async () => {
      replyForm.$emit('cancel');
      await nextTick();

      expect(Boolean(wrapper.vm.$refs.commentForm)).toBe(false);
    });

    it('should set placeholder correctly when creating-note:start event is fired', async () => {
      replyForm.$emit('creating-note:start', {
        body: 'another example note',
        bodyHtml: '<p data-sourcepos="1:1-1:29" dir="auto">another example note</p>',
      });

      await nextTick();
      const placeholderNote = wrapper.findComponent(PlaceholderNote).props('note');
      expect(placeholderNote).toMatchObject({
        body: 'another example note',
        bodyHtml: '<p data-sourcepos="1:1-1:29" dir="auto">another example note</p>',
      });
    });

    it('should remove placeholder note when creating-note:done event is fired', async () => {
      replyForm.$emit('creating-note:done');

      await nextTick();
      const placeholderNote = wrapper.findComponent(PlaceholderNote);
      expect(placeholderNote.exists()).toBe(false);
    });

    it('should remove placeholer when creating-note:success event is fired', async () => {
      const newReply = {
        ...note,
        id: 'gid://gitlab/DiscussionNote/1525',
      };

      replyForm.$emit('creating-note:success', { notes: { nodes: [newReply] } });
      await nextTick();

      const placeholderNote = wrapper.findComponent(PlaceholderNote);
      expect(placeholderNote.exists()).toBe(false);
    });
  });
});
