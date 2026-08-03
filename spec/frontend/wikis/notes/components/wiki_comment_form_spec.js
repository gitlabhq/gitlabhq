import { GlAlert, GlButton } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { clearDraft } from '~/lib/utils/autosave';
import WikiCommentForm from '~/wikis/wiki_notes/components/wiki_comment_form.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WikiDiscussionsSignedOut from '~/wikis/wiki_notes/components/wiki_discussions_signed_out.vue';
import createWikiPageNoteMutation from '~/wikis/wiki_notes/graphql/create_wiki_page_note.mutation.graphql';
import updateWikiPageNoteMutation from '~/wikis/wiki_notes/graphql/update_wiki_page_note.mutation.graphql';
import * as secretsDetection from '~/lib/utils/secret_detection';
import * as confirmViaGLModal from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import { wikiCommentFormProvideData, noteableId, note } from '../mock_data';

jest.mock('~/lib/utils/autosave');

Vue.use(VueApollo);

// The WikiPageNote fragment selects a few fields the shared `note` mock does not carry.
const wikiPageNote = {
  ...note,
  author: {
    ...note.author,
    emails: { __typename: 'EmailConnection', nodes: [] },
  },
  lastEditedBy: null,
  awardEmoji: { __typename: 'AwardEmojiConnection', nodes: [] },
};

const createNoteResponse = {
  data: {
    createNote: {
      __typename: 'CreateNotePayload',
      errors: [],
      note: {
        __typename: 'Note',
        id: 'gid://gitlab/DiscussionNote/1524',
        discussion: {
          __typename: 'Discussion',
          id: '2',
          resolvable: true,
          notes: { __typename: 'NoteConnection', nodes: [wikiPageNote] },
        },
      },
    },
    discussionToggleResolve: {
      __typename: 'DiscussionToggleResolvePayload',
      errors: [],
      discussion: { __typename: 'Discussion', id: '2', resolved: true },
    },
  },
};

const updateNoteResponse = {
  data: {
    updateNote: {
      __typename: 'UpdateNotePayload',
      errors: [],
      note: { ...wikiPageNote, id: '1' },
    },
  },
};

describe('WikiCommentForm', () => {
  let wrapper;
  let createNoteHandler;
  let updateNoteHandler;

  beforeEach(() => {
    createNoteHandler = jest.fn().mockResolvedValue(createNoteResponse);
    updateNoteHandler = jest.fn().mockResolvedValue(updateNoteResponse);
  });

  const createComponent = ({ props, provideData } = {}) => {
    const apolloProvider = createMockApollo([
      [createWikiPageNoteMutation, createNoteHandler],
      [updateWikiPageNoteMutation, updateNoteHandler],
    ]);

    wrapper = shallowMountExtended(WikiCommentForm, {
      propsData: { noteableId, noteId: '12', discussionId: '1', ...props },
      provide: { ...wikiCommentFormProvideData, ...provideData },
      apolloProvider,
      stubs: {
        GlButton,
        MarkdownEditor: {
          template: '<div></div>',
          props: {
            value: '',
            autofocus: false,
          },
          methods: {
            focus: jest.fn(),
          },
        },
      },
    });
  };

  const findWikiDiscussionsSignedOut = () => wrapper.findComponent(WikiDiscussionsSignedOut);
  const findWikiNoteCommentForm = () => wrapper.findByTestId('wiki-note-comment-form');
  const findResolveCheckbox = () => wrapper.findComponentByTestId('wiki-note-resolve-checkbox');
  const findUnresolveCheckbox = () => wrapper.findByTestId('wiki-note-unresolve-checkbox');

  describe('user is not logged in', () => {
    beforeEach(() => {
      createComponent({
        provideData: {
          currentUserData: null,
        },
      });
    });

    it('should only render wiki discussion signed out component', () => {
      expect(findWikiDiscussionsSignedOut().exists()).toBe(true);
      expect(findWikiNoteCommentForm().exists()).toBe(false);
    });
  });

  describe('user is logged in', () => {
    describe('user cannot create note', () => {
      beforeEach(() => {
        createComponent({
          provideData: {
            isContainerArchived: true,
          },
        });
      });

      it('does not render contents', () => {
        expect(findWikiDiscussionsSignedOut().exists()).toBe(false);
        expect(findWikiNoteCommentForm().exists()).toBe(false);
      });
    });

    describe('user can create note', () => {
      beforeEach(() => {
        createComponent();
      });

      it('should only render the wiki comment form', () => {
        expect(findWikiDiscussionsSignedOut().exists()).toBe(false);
        expect(findWikiNoteCommentForm().exists()).toBe(true);
      });

      it('should not autofocus on themarkdown editor when isReply and isEdit are false', () => {
        expect(wrapper.vm.$refs.markdownEditor.autofocus).toBe(false);
      });

      it('should autofocus on the markdown editor when isReply is true', () => {
        createComponent({ props: { isReply: true } });
        expect(wrapper.vm.$refs.markdownEditor.autofocus).toBe(true);
      });

      it('should autofocus on the markdown editor when isEdit is true', () => {
        createComponent({ props: { isEdit: true } });
        expect(wrapper.vm.$refs.markdownEditor.autofocus).toBe(true);
      });

      it('should display resolve checkbox when isReply is true', () => {
        createComponent({ props: { isReply: true, canResolve: true } });
        expect(findResolveCheckbox().exists()).toBe(true);
        expect(findUnresolveCheckbox().exists()).toBe(false);
      });

      it('should not display resolve checkbox when canResolve is false, even when isReply is true', () => {
        createComponent({ props: { isReply: true, canResolve: false } });
        expect(findResolveCheckbox().exists()).toBe(false);
        expect(findUnresolveCheckbox().exists()).toBe(false);
      });

      it('should display unresolve checkbox when isReply is true and discussionResolved is true', () => {
        createComponent({
          props: { isReply: true, discussionResolved: true, canResolve: true },
        });
        expect(findResolveCheckbox().exists()).toBe(false);
        expect(findUnresolveCheckbox().exists()).toBe(true);
      });

      it('should not display any resolve checkbox when isReply is false', () => {
        createComponent({ props: { isReply: false } });
        expect(findResolveCheckbox().exists()).toBe(false);
        expect(findUnresolveCheckbox().exists()).toBe(false);
      });

      describe('handle errors', () => {
        beforeEach(async () => {
          wrapper.vm.setError(['could not submit data']);
          await nextTick();
        });

        it('should not display error box when there are no errors', async () => {
          wrapper.vm.setError([]);
          await nextTick();
          expect(wrapper.findComponent(GlAlert).exists()).toBe(false);
        });

        it('should display error correctly', async () => {
          expect(await wrapper.findComponent(GlAlert).text()).toBe('could not submit data');
        });
      });

      describe('handle save', () => {
        const createWrapperWithNote = (props) => {
          createComponent({
            props: {
              discussionId: '1',
              noteableId: '1',
              internal: false,
              ...props,
            },
          });
          wrapper.vm.onInput('Test comment');
        };

        beforeEach(() => {
          createWrapperWithNote();
        });

        afterEach(() => {
          jest.restoreAllMocks();
        });

        it('should check for sensitive tokens in the note', async () => {
          const detectAndConfirmSensitiveTokens = jest.spyOn(
            secretsDetection,
            'detectAndConfirmSensitiveTokens',
          );

          await wrapper.vm.handleSave();

          expect(detectAndConfirmSensitiveTokens).toHaveBeenCalledWith({ content: 'Test comment' });
        });

        it('should not emit the creating-note-start event when note is empty', async () => {
          createComponent();
          await wrapper.vm.handleSave();
          expect(Boolean(wrapper.emitted('creating-note-start'))).toBe(false);
        });

        it('should clear the editor content', () => {
          createWrapperWithNote();
          wrapper.vm.handleSave();
          const content = wrapper.vm.$refs.markdownEditor.value;
          expect(content).toBe('');
        });

        it('should emit the creating-note-start event with the correct data when isEdit is true', async () => {
          createWrapperWithNote({ isEdit: true });
          wrapper.vm.handleSave();
          await nextTick();

          expect(wrapper.emitted('creating-note-start')).toMatchObject([
            [
              {
                body: 'Test comment',
                id: 'gid://gitlab/Note/12',
              },
            ],
          ]);
        });

        it('should emit the creating-note-start event with the correct data when isReply is true', async () => {
          createWrapperWithNote({ isReply: true });
          wrapper.vm.handleSave();
          await nextTick();
          expect(wrapper.emitted('creating-note-start')).toMatchObject([
            [
              {
                body: 'Test comment',
                discussionId: '1',
                individualNote: false,
                internal: false,
                noteableId: '1',
              },
            ],
          ]);
        });

        it('should emit the creating-note-start event with the correct data when isReply and isEdit are false', async () => {
          wrapper.vm.handleSave();
          await nextTick();
          expect(wrapper.emitted('creating-note-start')).toMatchObject([
            [
              {
                body: 'Test comment',
                discussionId: null,
                individualNote: false,
                internal: false,
                noteableId: '1',
              },
            ],
          ]);
        });

        describe('submitting a note', () => {
          it('should call the update note mutation with the correct data when isEdit is true', async () => {
            createWrapperWithNote({ isEdit: true });
            await wrapper.vm.handleSave();

            expect(updateNoteHandler).toHaveBeenCalledWith({
              input: {
                body: 'Test comment',
                id: 'gid://gitlab/Note/12',
              },
            });
          });

          it('should call the create note mutation with the correct data when isReply is true', async () => {
            createWrapperWithNote({ isReply: true });
            await wrapper.vm.handleSave();

            expect(createNoteHandler).toHaveBeenCalledWith(
              expect.objectContaining({
                createNoteInput: {
                  body: 'Test comment',
                  noteableId: '1',
                  discussionId: '1',
                  internal: false,
                },
              }),
            );
          });

          it('should call the create note mutation with the correct data when isReply and isEdit are false', async () => {
            await wrapper.vm.handleSave();

            expect(createNoteHandler).toHaveBeenCalledWith(
              expect.objectContaining({
                createNoteInput: {
                  body: 'Test comment',
                  noteableId: '1',
                  discussionId: null,
                  internal: false,
                },
              }),
            );
          });

          it('should call the create note mutation with the correct data when resolve is selected', async () => {
            createWrapperWithNote({ canResolve: true, isReply: true, discussionId: '1' });
            await findResolveCheckbox().vm.$emit('input', true);
            await wrapper.vm.handleSave();

            expect(createNoteHandler).toHaveBeenCalledWith({
              shouldChangeResolvedState: true,
              shouldCreateNote: true,
              createNoteInput: {
                body: 'Test comment',
                noteableId: '1',
                discussionId: '1',
                internal: false,
              },
              discussionToggleResolveInput: {
                id: '1',
                resolve: true,
              },
            });
          });

          it('should not start submitting if the user does not confirm to continue with sensitive tokens', async () => {
            jest
              .spyOn(secretsDetection, 'detectAndConfirmSensitiveTokens')
              .mockImplementation(() => false);

            await wrapper.vm.handleSave();
            expect(Boolean(wrapper.emitted('creating-note-start'))).toBe(false);
          });

          it('should start submitting if the user confirms to continue with sensitive tokens', async () => {
            // also applies to when there are no sensitive tokens in the note
            jest
              .spyOn(secretsDetection, 'detectAndConfirmSensitiveTokens')
              .mockImplementation(() => true);

            await wrapper.vm.handleSave();
            expect(Boolean(wrapper.emitted('creating-note-start'))).toBe(true);
          });
        });

        describe('when there is no error while submitting', () => {
          beforeEach(() => {
            wrapper.vm.onInput('comment');
          });

          it('should emit the creating-note-success event with the correct data when isEdit is true', async () => {
            createWrapperWithNote({ isEdit: true });
            await wrapper.vm.handleSave();

            expect(wrapper.emitted('creating-note-success')).toMatchObject([[{ id: '1' }]]);
          });

          it('should emit the creating-note-success event with the correct data when isEdit is false', async () => {
            createWrapperWithNote({ isEdit: false });
            await wrapper.vm.handleSave();

            expect(wrapper.emitted('creating-note-success')).toMatchObject([[{ id: '2' }]]);
          });

          it('should set note to empty string', async () => {
            await wrapper.vm.handleSave();
            expect(wrapper.vm.$refs.markdownEditor.value).toBe('');
          });

          it('should clear the autosave drafts for the note and the internal note flag', async () => {
            await wrapper.vm.handleSave();

            expect(clearDraft).toHaveBeenCalledWith(wrapper.vm.autosaveKey);
            expect(clearDraft).toHaveBeenCalledWith(wrapper.vm.autosaveKeyInternalNote);
          });
        });

        describe('when there is an error while submitting', () => {
          beforeEach(() => {
            createNoteHandler.mockRejectedValue(new Error('random error'));
          });

          it('should emit the creating-note-failed event with the correct value', async () => {
            await wrapper.vm.handleSave();

            expect(wrapper.emitted('creating-note-failed')).toHaveLength(1);
            expect(wrapper.emitted('creating-note-failed')[0][0].message).toBe('random error');
          });

          it('should set the note to the previous value', async () => {
            await wrapper.vm.handleSave();
            expect(wrapper.vm.$refs.markdownEditor.value).toBe('Test comment');
          });

          it('should set the errors with the correct value', async () => {
            await wrapper.vm.handleSave();
            const glAlert = wrapper.findComponent(GlAlert);

            expect(await glAlert.text()).toBe(
              'Comment could not be submitted: An unexpected error occurred trying to submit your comment. Please try again..',
            );
          });
        });
      });

      describe('handle comment button and internal note check box', () => {
        const submitButton = () => wrapper.findComponentByTestId('wiki-note-comment-button');
        const internalNoteCheckbox = () => wrapper.findByTestId('wiki-internal-note-checkbox');

        beforeEach(() => {
          createComponent({ props: { canSetInternalNote: true } });
        });

        it('should render both correctly', async () => {
          expect(await submitButton().text()).toBe('Comment');
          expect(internalNoteCheckbox().exists()).toBe(true);
        });

        it('should render neither when isReply is true', () => {
          createComponent({ props: { isReply: true } });
          expect(submitButton().exists()).toBe(false);
          expect(internalNoteCheckbox().exists()).toBe(false);
        });

        it('should render neither when isEdit is true', () => {
          createComponent({ props: { isEdit: true } });
          expect(submitButton().exists()).toBe(false);
          expect(internalNoteCheckbox().exists()).toBe(false);
        });

        it('should disable submit button when editor it is empty', () => {
          expect(submitButton().props('disabled')).toBe(true);
        });

        it('should not disable submit button editor when empty', async () => {
          wrapper.vm.onInput('comment');

          await nextTick();
          expect(submitButton().props('disabled')).toBe(false);
        });

        it('should disable editor when submitting', () => {
          wrapper.vm.handleSave(); // not waiting for it to finish
          expect(submitButton().props('disabled')).toBe(true);
        });
      });

      describe('reply and edit buttons', () => {
        const saveButton = () => wrapper.findComponentByTestId('wiki-note-save-button');
        const cancelButton = () => wrapper.findByTestId('wiki-note-cancel-button');

        beforeEach(() => {
          createComponent({ props: { isEdit: true } });
        });

        it('should render both save and cancel with correct text buttons when isEdit is true', async () => {
          expect(await saveButton().text()).toBe('Save comment');
          expect(await cancelButton().text()).toBe('Cancel');
        });

        it('should render both save and cancel with correct text buttons when isReply is true', async () => {
          createComponent({ props: { isReply: true, isEdit: false } });
          expect(await saveButton().text()).toBe('Reply');
          expect(await cancelButton().text()).toBe('Cancel');
        });

        it('should not render either button when isEdit and isReply are false', () => {
          createComponent({ props: { isReply: false, isEdit: false } });
          expect(saveButton().exists()).toBe(false);
          expect(cancelButton().exists()).toBe(false);
        });

        it('should be disabled when editor it is empty', () => {
          expect(saveButton().props('disabled')).toBe(true);
        });

        it('should not be disabled editor when empty', async () => {
          wrapper.vm.onInput('comment');
          await nextTick();
          expect(saveButton().props('disabled')).toBe(false);
        });

        it('should disable editor when submitting', () => {
          wrapper.vm.handleSave();
          expect(saveButton().props('disabled')).toBe(true);
        });
      });

      describe('handleCancel', () => {
        afterEach(() => {
          jest.clearAllMocks();
        });

        it('should emit cancel event when note is empty', async () => {
          await wrapper.vm.handleCancel();
          expect(Boolean(wrapper.emitted('cancel'))).toBe(true);
        });

        describe('when note is not empty', () => {
          const createWrapperWithNote = (props) => {
            createComponent({
              props,
            });

            wrapper.vm.onInput('Test comment');
          };

          beforeEach(() => {
            createWrapperWithNote();
          });

          it('should confirm if the user wants to cancel with the correct text, when isEdit is true', async () => {
            createWrapperWithNote({ isEdit: true });

            const confirmActionSpy = jest
              .spyOn(confirmViaGLModal, 'confirmAction')
              .mockImplementation(() => false);

            await wrapper.vm.handleCancel();
            expect(confirmActionSpy).toHaveBeenCalledWith(
              'Are you sure you want to cancel editing this comment?',
              {
                primaryBtnText: 'Discard changes',
                cancelBtnText: 'Continue editing',
              },
            );
          });

          it('should confirm if the user wants to cancel with the correct text, when isReply is true', async () => {
            createWrapperWithNote({ isReply: true });

            const confirmActionSpy = jest
              .spyOn(confirmViaGLModal, 'confirmAction')
              .mockImplementation(() => false);

            await wrapper.vm.handleCancel();

            expect(confirmActionSpy).toHaveBeenCalledWith(
              'Are you sure you want to cancel creating this comment?',
              {
                primaryBtnText: 'Discard changes',
                cancelBtnText: 'Continue creating',
              },
            );
          });

          it('should emit cancel if user confirms to cancel', async () => {
            jest.spyOn(confirmViaGLModal, 'confirmAction').mockImplementation(() => true);
            await wrapper.vm.handleCancel();

            expect(Boolean(wrapper.emitted('cancel'))).toBe(true);
          });

          it('should not emit cancel if user does not confirm to cancel', async () => {
            jest.spyOn(confirmViaGLModal, 'confirmAction').mockImplementation(() => false);
            await wrapper.vm.handleCancel();

            expect(Boolean(wrapper.emitted('cancel'))).toBe(false);
          });
        });
      });
    });
  });
});
