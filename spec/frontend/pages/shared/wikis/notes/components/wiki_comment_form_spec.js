import { GlAlert, GlFormCheckbox, GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import WikiCommentForm from '~/pages/shared/wikis/wiki_notes/components/wiki_comment_form.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WikiDiscussionsSignedOut from '~/pages/shared/wikis/wiki_notes/components/wiki_discussions_signed_out.vue';
import WikiDiscussionLocked from '~/pages/shared/wikis/wiki_notes/components/wiki_discussion_locked.vue';
import * as secretsDetection from '~/lib/utils/secret_detection';
import * as confirmViaGLModal from '~/lib/utils/confirm_via_gl_modal/confirm_action';
import { wikiCommentFormProvideData, noteableId } from '../mock_data';

describe('WikiCommentForm', () => {
  let wrapper;

  const $apollo = {
    mutate: jest.fn(),
  };

  const createWrapper = ({ props, provideData } = {}) =>
    shallowMountExtended(WikiCommentForm, {
      propsData: { noteableId, noteId: '12', discussionId: '1', ...props },
      provide: { ...wikiCommentFormProvideData, ...provideData },
      mocks: {
        $apollo,
      },
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

  const wikiCommentContainer = () => wrapper.findByTestId('wiki-note-comment-form-container');

  describe('user is not logged in', () => {
    beforeEach(() => {
      wrapper = createWrapper({
        provideData: {
          currentUserData: null,
        },
      });
    });

    it('should only render wiki discussion signed out component', () => {
      expect(wikiCommentContainer().element.children).toHaveLength(1);

      const wikiDiscussionsSignedOut =
        wikiCommentContainer().findComponent(WikiDiscussionsSignedOut);
      expect(wikiDiscussionsSignedOut.exists()).toBe(true);
    });
  });

  describe('user is logged in', () => {
    describe('user cannot create note', () => {
      beforeEach(() => {
        wrapper = createWrapper({
          provideData: {
            isContainerArchived: true,
          },
        });
      });

      it('should render only wiki discussion locked component when user cannot create note', () => {
        expect(wikiCommentContainer().element.children).toHaveLength(1);

        const wikiDiscussionLocked = wikiCommentContainer().findComponent(WikiDiscussionLocked);
        expect(wikiDiscussionLocked.exists()).toBe(true);
      });
    });

    describe('user can create note', () => {
      beforeEach(() => {
        wrapper = createWrapper();
      });

      it('should render only the wiki comment form', () => {
        expect(wikiCommentContainer().element.children).toHaveLength(1);

        const commentForm = wikiCommentContainer().find('[data-testid=wiki-note-comment-form]');
        expect(commentForm.exists()).toBe(true);
      });

      it('should not autofocus on themarkdown editor when isReply and isEdit are false', () => {
        expect(wrapper.vm.$refs.markdownEditor.autofocus).toBe(false);
      });

      it('should autofocus on the markdown editor when isReply is true', () => {
        wrapper = createWrapper({ props: { isReply: true } });
        expect(wrapper.vm.$refs.markdownEditor.autofocus).toBe(true);
      });

      it('should autofocus on the markdown editor when isEdit is true', () => {
        wrapper = createWrapper({ props: { isEdit: true } });
        expect(wrapper.vm.$refs.markdownEditor.autofocus).toBe(true);
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
          wrapper = createWrapper({
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

        it('should not emit the creating-note:start event when note is empty', async () => {
          wrapper = createWrapper();
          await wrapper.vm.handleSave();
          expect(Boolean(wrapper.emitted('creating-note:start'))).toBe(false);
        });

        it('should clear the editor content', () => {
          createWrapperWithNote();
          wrapper.vm.handleSave();
          const content = wrapper.vm.$refs.markdownEditor.value;
          expect(content).toBe('');
        });

        it('should emit the creating-note:start event with the correct data when isEdit is true', async () => {
          createWrapperWithNote({ isEdit: true });
          wrapper.vm.handleSave();
          await nextTick();

          expect(wrapper.emitted('creating-note:start')).toMatchObject([
            [
              {
                body: 'Test comment',
                id: 'gid://gitlab/Note/12',
              },
            ],
          ]);
        });

        it('should emit the creating-note:start event with the correct data when isReply is true', async () => {
          createWrapperWithNote({ isReply: true });
          wrapper.vm.handleSave();
          await nextTick();
          expect(wrapper.emitted('creating-note:start')).toMatchObject([
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

        it('should emit the creating-note:start event with the correct data when isReply and isEdit are false', async () => {
          wrapper.vm.handleSave();
          await nextTick();
          expect(wrapper.emitted('creating-note:start')).toMatchObject([
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
          it('should call apollo mutate with the correct data when isEdit is true', async () => {
            createWrapperWithNote({ isEdit: true });
            await wrapper.vm.handleSave();
            expect($apollo.mutate).toHaveBeenCalledWith({
              mutation: expect.any(Object),
              variables: {
                input: {
                  body: 'Test comment',
                  id: 'gid://gitlab/Note/12',
                },
              },
            });
          });

          it('should call apollo mutate with the correct data when isReply is true', async () => {
            createWrapperWithNote({ isReply: true });
            await wrapper.vm.handleSave();
            expect($apollo.mutate).toHaveBeenCalledWith({
              mutation: expect.any(Object),
              variables: {
                input: {
                  body: 'Test comment',
                  noteableId: '1',
                  discussionId: '1',
                  internal: false,
                },
              },
            });
          });

          it('should call apollo mutate with the correct data when isReply and isEdit are false', async () => {
            await wrapper.vm.handleSave();

            expect($apollo.mutate).toHaveBeenCalledWith({
              mutation: expect.any(Object),
              variables: {
                input: {
                  body: 'Test comment',
                  noteableId: '1',
                  discussionId: null,
                  internal: false,
                },
              },
            });
          });

          it('should not start sumitting if the user does not confirm to continue with sensitive tokens', async () => {
            jest
              .spyOn(secretsDetection, 'detectAndConfirmSensitiveTokens')
              .mockImplementation(() => false);

            await wrapper.vm.handleSave();
            expect(Boolean(wrapper.emitted('creating-note:start'))).toBe(false);
          });

          it('should start sumitting if the user confirms to continue with sensitive tokens', async () => {
            // also applies to when there are no sensitive tokens in the note
            jest
              .spyOn(secretsDetection, 'detectAndConfirmSensitiveTokens')
              .mockImplementation(() => true);

            await wrapper.vm.handleSave();
            expect(Boolean(wrapper.emitted('creating-note:start'))).toBe(true);
          });
        });

        describe('when there is no error while submitting', () => {
          beforeEach(() => {
            wrapper.vm.onInput('comment');
            $apollo.mutate.mockResolvedValue({
              data: {
                updateNote: { note: { id: '1' } },
                createNote: { note: { discussion: { id: '2' } } },
              },
            });
          });

          it('should emit the creating-note:success event with the correct data when isEdit is true', async () => {
            createWrapperWithNote({ isEdit: true });
            await wrapper.vm.handleSave();

            expect(wrapper.emitted('creating-note:success')).toStrictEqual([[{ id: '1' }]]);
          });

          it('should emit the creating-note:success event with the correct data when isEdit is false', async () => {
            createWrapperWithNote({ isEdit: false });
            await wrapper.vm.handleSave();

            expect(wrapper.emitted('creating-note:success')).toStrictEqual([[{ id: '2' }]]);
          });

          it('should set note to empty string', async () => {
            await wrapper.vm.handleSave();
            expect(wrapper.vm.$refs.markdownEditor.value).toBe('');
          });
        });

        describe('when there is an error while submitting', () => {
          beforeEach(() => {
            $apollo.mutate.mockRejectedValue('random error');
          });

          it('should emit the creating-note:failed event with the correct value', async () => {
            await wrapper.vm.handleSave();

            expect(wrapper.emitted('creating-note:failed')).toStrictEqual([['random error']]);
          });

          it('should set the note to the previous value', async () => {
            await wrapper.vm.handleSave();
            expect(wrapper.vm.$refs.markdownEditor.value).toBe('Test comment');
          });

          it('should set the errors with the correct value', async () => {
            await wrapper.vm.handleSave();
            const glAlert = wrapper.findComponent(GlAlert);

            expect(await glAlert.text()).toBe(
              'Your comment could not be submitted! Please check your network connection and try again.',
            );
          });
        });
      });

      describe('handle comment button and internal note check box', () => {
        const submitButton = () => wrapper.findByTestId('wiki-note-comment-button');
        const internalNoteCheckbox = () => wrapper.findComponent(GlFormCheckbox);

        beforeEach(() => {
          wrapper = createWrapper({ props: { canSetInternalNote: true } });
        });

        it('should render both correctly', async () => {
          expect(await submitButton().text()).toBe('Comment');
          expect(internalNoteCheckbox().exists()).toBe(true);
        });

        it('should render neither when isReply is true', () => {
          wrapper = createWrapper({ props: { isReply: true } });
          expect(submitButton().exists()).toBe(false);
          expect(internalNoteCheckbox().exists()).toBe(false);
        });

        it('should render neither when isEdit is true', () => {
          wrapper = createWrapper({ props: { isEdit: true } });
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
        const saveButton = () => wrapper.findByTestId('wiki-note-save-button');
        const cancelButton = () => wrapper.findByTestId('wiki-note-cancel-button');

        beforeEach(() => {
          wrapper = createWrapper({ props: { isEdit: true } });
        });

        it('should render both save and cancel with correct text buttons when isEdit is true', async () => {
          expect(await saveButton().text()).toBe('Save comment');
          expect(await cancelButton().text()).toBe('Cancel');
        });

        it('should render both save and cancel with correct text buttons when isReply is true', async () => {
          wrapper = createWrapper({ props: { isReply: true, isEdit: false } });
          expect(await saveButton().text()).toBe('Reply');
          expect(await cancelButton().text()).toBe('Cancel');
        });

        it('should not render either button when isEdit and isReply are false', () => {
          wrapper = createWrapper({ props: { isReply: false, isEdit: false } });
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
            wrapper = createWrapper({
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
