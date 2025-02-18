import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WikiNote from '~/pages/shared/wikis/wiki_notes/components/wiki_note.vue';
import NoteHeader from '~/pages/shared/wikis/wiki_notes/components/note_header.vue';
import NoteActions from '~/pages/shared/wikis/wiki_notes/components/note_actions.vue';
import NoteBody from '~/pages/shared/wikis/wiki_notes/components/note_body.vue';
import deleteNoteMutation from '~/wikis/graphql/notes/delete_wiki_page_note.mutation.graphql';
import wikiNoteToggleAwardEmojiMutation from '~/wikis/graphql/notes/wiki_note_toggle_award_emoji.mutation.graphql';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import AwardsList from '~/vue_shared/components/awards_list.vue';
import * as autosave from '~/lib/utils/autosave';
import * as confirmViaGLModal from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import * as alert from '~/alert';
import {
  noteableType,
  currentUserData,
  note,
  noteableId,
  queryVariables,
  awardEmoji,
} from '../mock_data';

describe('WikiNote', () => {
  let wrapper;

  const $apollo = {
    mutate: jest.fn(),
  };

  const noteWithEmojiAward = {
    ...note,
    awardEmoji: {
      nodes: [awardEmoji],
    },
  };

  const createWrapper = (props) => {
    return shallowMountExtended(WikiNote, {
      propsData: {
        noteableId,
        ...props,
      },
      mocks: {
        $apollo,
      },
      provide: {
        noteableType,
        currentUserData,
        queryVariables,
      },
      stubs: {
        GlAvatarLink: {
          template: '<div><slot></slot></div>',
          props: ['href', 'data-user-id', 'data-username'],
        },
        GlAvatar: {
          template: '<img/>',
          props: ['src', 'entity-name', 'alt'],
        },
      },
    });
  };

  beforeEach(() => {
    wrapper = createWrapper({ note });
  });

  describe('renders correctly by default', () => {
    it('should render time line entry item correctly', () => {
      const timelineEntryItem = wrapper.findComponent(TimelineEntryItem);

      expect(timelineEntryItem.element.classList).not.toContain(
        'gl-opacity-5',
        'gl-ponter-events-none',
        'is-editable',
        'internal-note',
      );
    });

    it('should render author avatar correctly', () => {
      const avatarLink = wrapper.findComponent(GlAvatarLink);

      expect(avatarLink.props()).toMatchObject({
        href: note.author.webPath,
        dataUserId: '1',
        dataUsername: 'root',
      });

      const avatar = avatarLink.findComponent(GlAvatar);

      expect(avatar.props()).toMatchObject({
        alt: note.author.name,
        entityName: note.author.username,
        src: note.author.avatarUrl,
      });
    });

    it('renders note header correctly', () => {
      const noteHeader = wrapper.findComponent(NoteHeader);

      expect(noteHeader.props()).toMatchObject({
        author: note.author,
        createdAt: note.createdAt,
      });
    });

    it('renders note actions correctly', () => {
      const noteActions = wrapper.findComponent(NoteActions);

      expect(noteActions.props()).toMatchObject({
        authorId: '1',
        noteUrl: note.url,
        showReply: true,
        showEdit: false,
        canReportAsAbuse: true,
      });
    });

    it('renders note body correctly', () => {
      const noteBody = wrapper.findComponent(NoteBody);

      expect(noteBody.props()).toMatchObject({
        note,
        noteableId,
        isEditing: false,
      });
    });

    it('should not render awards list', () => {
      expect(wrapper.findComponent(AwardsList).exists()).toBe(false);
    });
  });

  describe('when note has emoji awards', () => {
    beforeEach(() => {
      noteWithEmojiAward.userPermissions.awardEmoji = true;

      wrapper = createWrapper({
        note: noteWithEmojiAward,
      });
    });

    it('should render awards list with the correct emojis', () => {
      const awardsList = wrapper.findComponent(AwardsList);
      expect(awardsList.props().awards).toMatchObject([awardEmoji]);
    });

    it('should pass canAwardEmoji prop as false when user cannot award emoji', () => {
      noteWithEmojiAward.userPermissions.awardEmoji = false;
      wrapper = createWrapper({ note: noteWithEmojiAward });

      const noteActions = wrapper.findComponent(NoteActions);
      expect(noteActions.props('canAwardEmoji')).toBe(false);
    });

    it('should pass canAwardEmoji prop to NoteActions as true when user can award emoji', () => {
      const noteActions = wrapper.findComponent(NoteActions);
      expect(noteActions.props('canAwardEmoji')).toBe(true);
    });
  });

  describe('when user is signed in', () => {
    beforeEach(() => {
      wrapper = createWrapper({ note });
    });

    it('should emit reply when reply event is fired from note actions', () => {
      const noteActions = wrapper.findComponent(NoteActions);
      noteActions.vm.$emit('reply');

      expect(Boolean(wrapper.emitted('reply'))).toBe(true);
    });

    it('should pass prop "showReply" as true to note actions when user can reply', () => {
      wrapper = createWrapper({ note });

      const noteActions = wrapper.findComponent(NoteActions);
      expect(noteActions.props().showReply).toBe(true);
    });

    it('should pass prop "showReply" as false to note actions when user cannot reply', () => {
      wrapper = createWrapper({
        note: {
          ...note,
          userPermissions: {
            ...note.userPermissions,
            createNote: false,
          },
        },
      });

      const noteActions = wrapper.findComponent(NoteActions);
      expect(noteActions.props().showReply).toBe(false);
    });

    describe('user cannot edit', () => {
      it('should pass false to showEdit prop of note actions', () => {
        const noteActions = wrapper.findComponent(NoteActions);
        expect(noteActions.props().showEdit).toBe(false);
      });

      it('should pass false to canEdit prop of note body', () => {
        const noteBody = wrapper.findComponent(NoteBody);
        expect(noteBody.props().canEdit).toBe(false);
      });
    });

    describe('user can edit', () => {
      const verifyEditingOrDeletingStyles = (applied = true) => {
        const timelineEntryItem = wrapper.findComponent(TimelineEntryItem);
        expect(timelineEntryItem.element.classList.contains('gl-opacity-5')).toBe(applied);
        expect(timelineEntryItem.element.classList.contains('gl-pointer-events-none')).toBe(
          applied,
        );
      };

      const verifyShowSpinner = () => {
        const noteHeader = wrapper.findComponent(NoteHeader);
        expect(noteHeader.props().showSpinner).toBe(true);
      };

      beforeEach(() => {
        wrapper = createWrapper({
          note: {
            ...note,
            userPermissions: {
              ...note.userPermissions,
              adminNote: true,
            },
          },
        });
      });

      it('should pass true to showEdit prop of note actions', () => {
        const noteActions = wrapper.findComponent(NoteActions);
        expect(noteActions.props().showEdit).toBe(true);
      });

      it('should pass true to canEdit prop of note body', () => {
        const noteBody = wrapper.findComponent(NoteBody);
        expect(noteBody.props().canEdit).toBe(true);
      });

      describe('when editing', () => {
        beforeEach(() => {
          wrapper.vm.toggleEditing(true);
        });

        afterEach(() => {
          jest.restoreAllMocks();
        });

        it('should pass isEditing prop as true to the note body', () => {
          const noteBody = wrapper.findComponent(NoteBody);
          expect(noteBody.props().isEditing).toBe(true);
        });

        it('should clear draft when isEditing is set to false', () => {
          const clearDraftSpy = jest.spyOn(autosave, 'clearDraft');
          wrapper.vm.toggleEditing(false);

          expect(clearDraftSpy).toHaveBeenCalled();
        });

        it('should pass down isEditing as false when cancel:edit event is fired from note body component', async () => {
          wrapper.findComponent(NoteBody).vm.$emit('cancel:edit');

          await nextTick();
          expect(wrapper.findComponent(NoteBody).props('isEditing')).toBe(false);
        });

        it('should pass down isEditing as false when creating-note:success event is fired from note body component', async () => {
          wrapper.findComponent(NoteBody).vm.$emit('creating-note:success');

          await nextTick();
          expect(wrapper.findComponent(NoteBody).props('isEditing')).toBe(false);
        });
      });

      describe('when not editing', () => {
        it('should pass down isEditing as false', () => {
          expect(wrapper.findComponent(NoteBody).props('isEditing')).toBe(false);
        });

        it('should pass down isEditing true when edit event is fired from note actions', async () => {
          wrapper.findComponent(NoteActions).vm.$emit('edit');

          await nextTick();
          expect(wrapper.findComponent(NoteBody).props('isEditing')).toBe(true);
        });
      });

      describe('when updating', () => {
        beforeEach(() => {
          wrapper.vm.toggleUpdating(true);
        });

        it('should add opacity and disable pointer events on timeline entry item', () => {
          verifyEditingOrDeletingStyles(true);
        });

        it('should show spinner on note header', () => {
          verifyEditingOrDeletingStyles(true);
        });

        it('should pass isEditing down as true and remove spinner when creating-note:done event is fired from note body component', async () => {
          wrapper.findComponent(NoteBody).vm.$emit('creating-note:done');

          await nextTick();
          expect(wrapper.findComponent(NoteBody).props('isEditing')).toBe(false);
          expect(wrapper.findComponent(NoteHeader).props('showSpinner')).toBe(false);
        });
      });

      describe('when not updating', () => {
        it('should add editing styles when creating-note:start event is fired from note body component', async () => {
          wrapper.findComponent(NoteBody).vm.$emit('creating-note:start');
          await nextTick();
          verifyEditingOrDeletingStyles();
        });

        it('should show spinner on note header when creating-note:start event is fired from note body component', async () => {
          wrapper.findComponent(NoteBody).vm.$emit('creating-note:start');
          await nextTick();
          verifyShowSpinner();
        });

        it('shoould not show spinner on note header', () => {
          const noteHeader = wrapper.findComponent(NoteHeader);
          expect(noteHeader.props().showSpinner).toBe(false);
        });

        it('should remove opacity and disable pointer events on timeline entry item', () => {
          verifyEditingOrDeletingStyles(false);
        });
      });

      describe('when deleting', () => {
        it('should add opacity and disable pointer events on timeline entry item', async () => {
          wrapper.vm.toggleDeleting(true);
          await nextTick();

          verifyEditingOrDeletingStyles();
        });

        describe('deleteNote', () => {
          beforeEach(() => {
            $apollo.mutate.mockClear();
          });

          afterEach(() => {
            jest.restoreAllMocks();
          });

          it('should confirm with user before deleting', () => {
            const confirmSpy = jest.spyOn(confirmViaGLModal, 'confirmAction');
            wrapper.vm.deleteNote();

            expect(confirmSpy).toHaveBeenCalledWith(
              'Are you sure you want to delete this comment?',
              {
                primaryBtnVariant: 'danger',
                primaryBtnText: 'Delete comment',
              },
            );
          });

          it('should not attempt to delete note if user does not confirm delete note action', () => {
            jest.spyOn(confirmViaGLModal, 'confirmAction').mockImplementation(() => false);

            wrapper.vm.deleteNote();
            expect($apollo.mutate).not.toHaveBeenCalled();
          });

          it('should attempt to delete note if user confirms delete note action', async () => {
            jest.spyOn(confirmViaGLModal, 'confirmAction').mockImplementation(() => true);

            await wrapper.vm.deleteNote();
            expect($apollo.mutate).toHaveBeenCalledWith({
              mutation: deleteNoteMutation,
              variables: {
                input: {
                  id: note.id,
                },
              },
            });
          });

          it('should handle error appropriately when delete note is not successful', async () => {
            jest.spyOn(confirmViaGLModal, 'confirmAction').mockImplementation(() => true);

            const createAlertSpy = jest.spyOn(alert, 'createAlert');

            $apollo.mutate.mockRejectedValue();

            await wrapper.vm.deleteNote();

            expect(wrapper.findComponent(TimelineEntryItem).exists()).toBe(true);
            expect(createAlertSpy).toHaveBeenCalledWith({
              message: 'Something went wrong while deleting your note. Please try again.',
            });

            await nextTick();
            verifyEditingOrDeletingStyles(false);
          });

          it('should emit "note-deleted" when delete note is successful', async () => {
            jest.spyOn(confirmViaGLModal, 'confirmAction').mockImplementation(() => true);
            $apollo.mutate.mockResolvedValue();

            await wrapper.vm.deleteNote();
            expect(Boolean(wrapper.emitted('note-deleted'))).toBe(true);
          });
        });
      });

      describe('when not deleting', () => {
        it('should not apply deleting styles', () => {
          verifyEditingOrDeletingStyles(false);
        });
      });
    });

    describe('user can award emoji', () => {
      beforeEach(() => {
        noteWithEmojiAward.userPermissions.awardEmoji = true;
      });

      describe('isEmojiPresentForCurrentUser', () => {
        afterEach(() => {
          jest.restoreAllMocks();
        });

        it.each`
          userId  | emojiName     | returnValue | description
          ${'70'} | ${'star'}     | ${true}     | ${'correct user id, correct name'}
          ${'1'}  | ${'star'}     | ${false}    | ${'incorrect user id, correct name'}
          ${'70'} | ${'bar'}      | ${false}    | ${'correct user id, incorrect name'}
          ${'2'}  | ${'thumbsup'} | ${false}    | ${'incorrect user id, incorrect name'}
        `(
          'should return true only when userId and emoji name match with their corresponding values in the emojiAward and false when any of they dont',
          ({ userId, emojiName, returnValue }) => {
            noteWithEmojiAward.awardEmoji.nodes[0].user.id = userId;

            wrapper = createWrapper({
              note: noteWithEmojiAward,
            });
            $apollo.mutate.mockResolvedValue({});

            const spy = jest.spyOn(wrapper.vm, 'isEmojiPresentForCurrentUser');
            const awardsList = wrapper.findComponent(AwardsList);
            awardsList.vm.$emit('award', emojiName);

            expect(spy).toHaveReturnedWith(returnValue);
          },
        );
      });

      describe('handleAwardEmoji', () => {
        beforeEach(() => {
          noteWithEmojiAward.userPermissions.awardEmoji = true;

          wrapper = createWrapper({
            note: noteWithEmojiAward,
          });
        });

        afterEach(() => {
          jest.restoreAllMocks();
        });

        it('should call the apollo mutation with the correct data when handleAwardEmoji is called with an emoji name', () => {
          $apollo.mutate.mockResolvedValue({});
          jest.spyOn(wrapper.vm, 'isEmojiPresentForCurrentUser').mockReturnValue(false);

          const awardsList = wrapper.findComponent(AwardsList);
          awardsList.vm.$emit('award', 'star');

          expect($apollo.mutate).toHaveBeenCalledWith({
            mutation: wikiNoteToggleAwardEmojiMutation,
            variables: {
              name: 'star',
              awardableId: note.id,
            },
            optimisticResponse: {
              awardEmojiToggle: {
                errors: [],
                toggledOn: true,
              },
            },
            update: expect.any(Function),
          });
        });

        it('should call the sentry capture exception function with the correct data if mutation fails', async () => {
          jest.spyOn(Sentry, 'captureException');
          $apollo.mutate.mockRejectedValue('error');

          const awardsList = wrapper.findComponent(AwardsList);
          awardsList.vm.$emit('award', 'star');

          await nextTick();
          expect(Sentry.captureException).toHaveBeenCalledWith('error');
        });
      });
    });
  });
});
