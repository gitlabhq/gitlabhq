import { GlAvatarLink, GlAvatar } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WikiNote from '~/pages/shared/wikis/wiki_notes/components/wiki_note.vue';
import NoteHeader from '~/pages/shared/wikis/wiki_notes/components/note_header.vue';
import NoteActions from '~/pages/shared/wikis/wiki_notes/components/note_actions.vue';
import NoteBody from '~/pages/shared/wikis/wiki_notes/components/note_body.vue';
import DeleteNoteMutation from '~/wikis/graphql/notes/delete_wiki_page_note.mutation.graphql';
import TimelineEntryItem from '~/vue_shared/components/notes/timeline_entry_item.vue';
import * as autosave from '~/lib/utils/autosave';
import * as confirmViaGLModal from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import * as alert from '~/alert';
import { noteableType, currentUserData, note, noteableId } from '../mock_data';

describe('WikiNote', () => {
  let wrapper;

  const $apollo = {
    mutate: jest.fn(),
  };

  const createWrapper = (props) => {
    return shallowMountExtended(WikiNote, {
      propsData: {
        note,
        noteableId,
        ...props,
      },
      mocks: {
        $apollo,
      },
      provide: {
        noteableType,
        currentUserData,
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
    wrapper = createWrapper();
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
        showReply: false,
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
  });

  describe('when user is signed in', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('should emit reply when reply event is fired from note actions', () => {
      const noteActions = wrapper.findComponent(NoteActions);
      noteActions.vm.$emit('reply');

      expect(Boolean(wrapper.emitted('reply'))).toBe(true);
    });

    it('should pass prop "showReply" as true to note actions when user can reply', () => {
      wrapper = createWrapper({
        userPermissions: {
          createNote: true,
        },
      });

      const noteActions = wrapper.findComponent(NoteActions);
      expect(noteActions.props().showReply).toBe(true);
    });

    it('should pass prop "showReply" as false to note actions when user cannot reply', () => {
      wrapper = createWrapper({
        userPermissions: {
          createNote: false,
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
            author: {
              ...note.author,
              id: 'gid://gitlab/User/70',
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
              mutation: DeleteNoteMutation,
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
  });
});
