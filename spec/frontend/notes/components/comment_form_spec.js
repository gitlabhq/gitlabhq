import { GlAlert } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Autosize from 'autosize';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import batchComments from '~/batch_comments/stores/modules/batch_comments';
import { refreshUserMergeRequestCounts } from '~/commons/nav/user_merge_requests';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import CommentForm from '~/notes/components/comment_form.vue';
import * as constants from '~/notes/constants';
import eventHub from '~/notes/event_hub';
import { COMMENT_FORM } from '~/notes/i18n';
import notesModule from '~/notes/stores/modules';
import { loggedOutnoteableData, notesDataMock, userDataMock, noteableDataMock } from '../mock_data';

jest.mock('autosize');
jest.mock('~/commons/nav/user_merge_requests');
jest.mock('~/flash');
jest.mock('~/gl_form');

Vue.use(Vuex);

describe('issue_comment_form component', () => {
  let store;
  let wrapper;
  let axiosMock;

  const findCloseReopenButton = () => wrapper.findByTestId('close-reopen-button');
  const findTextArea = () => wrapper.findByTestId('comment-field');
  const findAddToReviewButton = () => wrapper.findByTestId('add-to-review-button');
  const findAddCommentNowButton = () => wrapper.findByTestId('add-comment-now-button');
  const findConfidentialNoteCheckbox = () => wrapper.findByTestId('confidential-note-checkbox');
  const findCommentGlDropdown = () => wrapper.findByTestId('comment-button');
  const findCommentButton = () => findCommentGlDropdown().find('button');
  const findErrorAlerts = () => wrapper.findAllComponents(GlAlert).wrappers;

  async function clickCommentButton({ waitForComponent = true, waitForNetwork = true } = {}) {
    findCommentButton().trigger('click');

    if (waitForComponent || waitForNetwork) {
      // Wait for the click to bubble out and trigger the handler
      await nextTick();

      if (waitForNetwork) {
        // Wait for the network request promise to resolve
        await nextTick();
      }
    }
  }

  function createStore({ actions = {} } = {}) {
    const baseModule = notesModule();

    return new Vuex.Store({
      ...baseModule,
      actions: {
        ...baseModule.actions,
        ...actions,
      },
    });
  }

  const createNotableDataMock = (data = {}) => {
    return {
      ...noteableDataMock,
      ...data,
    };
  };

  const notableDataMockCanUpdateIssuable = createNotableDataMock({
    current_user: { can_update: true, can_create_note: true },
  });

  const notableDataMockCannotUpdateIssuable = createNotableDataMock({
    current_user: { can_update: false, can_create_note: true },
  });

  const mountComponent = ({
    initialData = {},
    noteableType = 'Issue',
    noteableData = noteableDataMock,
    notesData = notesDataMock,
    userData = userDataMock,
    features = {},
    mountFunction = shallowMount,
  } = {}) => {
    store.dispatch('setNoteableData', noteableData);
    store.dispatch('setNotesData', notesData);
    store.dispatch('setUserData', userData);

    wrapper = extendedWrapper(
      mountFunction(CommentForm, {
        propsData: {
          noteableType,
        },
        data() {
          return {
            ...initialData,
          };
        },
        store,
        provide: {
          glFeatures: features,
        },
      }),
    );
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    store = createStore();
  });

  afterEach(() => {
    axiosMock.restore();
    wrapper.destroy();
  });

  describe('user is logged in', () => {
    describe('handleSave', () => {
      it('should request to save note when note is entered', () => {
        mountComponent({ mountFunction: mount, initialData: { note: 'hello world' } });

        jest.spyOn(wrapper.vm, 'saveNote').mockResolvedValue();
        jest.spyOn(wrapper.vm, 'resizeTextarea');
        jest.spyOn(wrapper.vm, 'stopPolling');

        findCloseReopenButton().trigger('click');

        expect(wrapper.vm.isSubmitting).toBe(true);
        expect(wrapper.vm.note).toBe('');
        expect(wrapper.vm.saveNote).toHaveBeenCalled();
        expect(wrapper.vm.stopPolling).toHaveBeenCalled();
        expect(wrapper.vm.resizeTextarea).toHaveBeenCalled();
      });

      it('does not report errors in the UI when the save succeeds', async () => {
        mountComponent({ mountFunction: mount, initialData: { note: '/label ~sdfghj' } });

        jest.spyOn(wrapper.vm, 'saveNote').mockResolvedValue();

        await clickCommentButton();

        // findErrorAlerts().exists returns false if *any* wrapper is empty,
        //   not necessarily that there aren't any at all.
        // We want to check here that there are none found, so we use the
        //   raw wrapper array length instead.
        expect(findErrorAlerts().length).toBe(0);
      });

      it.each`
        httpStatus | errors
        ${400}     | ${[COMMENT_FORM.GENERIC_UNSUBMITTABLE_NETWORK]}
        ${422}     | ${['error 1']}
        ${422}     | ${['error 1', 'error 2']}
        ${422}     | ${['error 1', 'error 2', 'error 3']}
      `(
        'displays the correct errors ($errors) for a $httpStatus network response',
        async ({ errors, httpStatus }) => {
          store = createStore({
            actions: {
              saveNote: jest.fn().mockRejectedValue({
                response: { status: httpStatus, data: { errors: { commands_only: errors } } },
              }),
            },
          });

          mountComponent({ mountFunction: mount, initialData: { note: '/label ~sdfghj' } });

          await clickCommentButton();

          const errorAlerts = findErrorAlerts();

          expect(errorAlerts.length).toBe(errors.length);
          errors.forEach((msg, index) => {
            const alert = errorAlerts[index];

            expect(alert.text()).toBe(msg);
          });
        },
      );

      it('should remove the correct error from the list when it is dismissed', async () => {
        const commandErrors = ['1', '2', '3'];
        store = createStore({
          actions: {
            saveNote: jest.fn().mockRejectedValue({
              response: { status: 422, data: { errors: { commands_only: [...commandErrors] } } },
            }),
          },
        });

        mountComponent({ mountFunction: mount, initialData: { note: '/label ~sdfghj' } });

        await clickCommentButton();

        let errorAlerts = findErrorAlerts();

        expect(errorAlerts.length).toBe(commandErrors.length);

        // dismiss the second error
        extendedWrapper(errorAlerts[1]).findByTestId('close-icon').trigger('click');
        // Wait for the dismissal to bubble out of the Alert component and be handled in this component
        await nextTick();
        // Refresh the list of alerts
        errorAlerts = findErrorAlerts();

        expect(errorAlerts.length).toBe(commandErrors.length - 1);
        // We want to know that the *correct* error was dismissed, not just that any one is gone
        expect(errorAlerts[0].text()).toBe(commandErrors[0]);
        expect(errorAlerts[1].text()).toBe(commandErrors[2]);
      });

      it('should toggle issue state when no note', () => {
        mountComponent({ mountFunction: mount });

        jest.spyOn(wrapper.vm, 'toggleIssueState');

        findCloseReopenButton().trigger('click');

        expect(wrapper.vm.toggleIssueState).toHaveBeenCalled();
      });

      it('should disable action button while submitting', async () => {
        mountComponent({ mountFunction: mount, initialData: { note: 'hello world' } });

        const saveNotePromise = Promise.resolve();

        jest.spyOn(wrapper.vm, 'saveNote').mockReturnValue(saveNotePromise);
        jest.spyOn(wrapper.vm, 'stopPolling');

        const actionButton = findCloseReopenButton();

        await actionButton.trigger('click');

        expect(actionButton.props('disabled')).toBe(true);

        await saveNotePromise;

        await nextTick();

        expect(actionButton.props('disabled')).toBe(false);
      });
    });

    describe('textarea', () => {
      describe('general', () => {
        it('should render textarea with placeholder', () => {
          mountComponent({ mountFunction: mount });

          expect(findTextArea().attributes('placeholder')).toBe(
            'Write a comment or drag your files here…',
          );
        });

        it('should make textarea disabled while requesting', async () => {
          mountComponent({ mountFunction: mount });

          jest.spyOn(wrapper.vm, 'stopPolling');
          jest.spyOn(wrapper.vm, 'saveNote').mockResolvedValue();

          await wrapper.setData({ note: 'hello world' });

          await findCommentButton().trigger('click');

          expect(findTextArea().attributes('disabled')).toBe('disabled');
        });

        it('should support quick actions', () => {
          mountComponent({ mountFunction: mount });

          expect(findTextArea().attributes('data-supports-quick-actions')).toBe('true');
        });

        it('should link to markdown docs', () => {
          mountComponent({ mountFunction: mount });

          const { markdownDocsPath } = notesDataMock;

          expect(wrapper.find(`a[href="${markdownDocsPath}"]`).text()).toBe('Markdown');
        });

        it('should link to quick actions docs', () => {
          mountComponent({ mountFunction: mount });

          const { quickActionsDocsPath } = notesDataMock;

          expect(wrapper.find(`a[href="${quickActionsDocsPath}"]`).text()).toBe('quick actions');
        });

        it('should resize textarea after note discarded', async () => {
          mountComponent({ mountFunction: mount, initialData: { note: 'foo' } });

          jest.spyOn(wrapper.vm, 'discard');

          wrapper.vm.discard();

          await nextTick();

          expect(Autosize.update).toHaveBeenCalled();
        });
      });

      describe('edit mode', () => {
        beforeEach(() => {
          mountComponent({ mountFunction: mount });
        });

        it('should enter edit mode when arrow up is pressed', () => {
          jest.spyOn(wrapper.vm, 'editCurrentUserLastNote');

          findTextArea().trigger('keydown.up');

          expect(wrapper.vm.editCurrentUserLastNote).toHaveBeenCalled();
        });

        it('inits autosave', () => {
          expect(wrapper.vm.autosave).toBeDefined();
          expect(wrapper.vm.autosave.key).toBe(`autosave/Note/Issue/${noteableDataMock.id}`);
        });
      });

      describe('event enter', () => {
        beforeEach(() => {
          mountComponent({ mountFunction: mount });
        });

        describe('when no draft exists', () => {
          it('should save note when cmd+enter is pressed', () => {
            jest.spyOn(wrapper.vm, 'handleSave');

            findTextArea().trigger('keydown.enter', { metaKey: true });

            expect(wrapper.vm.handleSave).toHaveBeenCalledWith();
          });

          it('should save note when ctrl+enter is pressed', () => {
            jest.spyOn(wrapper.vm, 'handleSave');

            findTextArea().trigger('keydown.enter', { ctrlKey: true });

            expect(wrapper.vm.handleSave).toHaveBeenCalledWith();
          });
        });

        describe('when a draft exists', () => {
          beforeEach(() => {
            store.registerModule('batchComments', batchComments());
            store.state.batchComments.drafts = [{ note: 'A' }];
          });

          it('should save note draft when cmd+enter is pressed', () => {
            jest.spyOn(wrapper.vm, 'handleSaveDraft');

            findTextArea().trigger('keydown.enter', { metaKey: true });

            expect(wrapper.vm.handleSaveDraft).toHaveBeenCalledWith();
          });

          it('should save note draft when ctrl+enter is pressed', () => {
            jest.spyOn(wrapper.vm, 'handleSaveDraft');

            findTextArea().trigger('keydown.enter', { ctrlKey: true });

            expect(wrapper.vm.handleSaveDraft).toHaveBeenCalledWith();
          });
        });
      });
    });

    describe('actions', () => {
      it('should be possible to close the issue', () => {
        mountComponent();

        expect(findCloseReopenButton().text()).toBe('Close issue');
      });

      it('should render comment button as disabled', () => {
        mountComponent();

        expect(findCommentGlDropdown().props('disabled')).toBe(true);
      });

      it('should enable comment button if it has note', async () => {
        mountComponent();

        await wrapper.setData({ note: 'Foo' });

        expect(findCommentGlDropdown().props('disabled')).toBe(false);
      });

      it('should update buttons texts when it has note', () => {
        mountComponent({ initialData: { note: 'Foo' } });

        expect(findCloseReopenButton().text()).toBe('Comment & close issue');
      });

      it('updates button text with noteable type', () => {
        mountComponent({ noteableType: constants.MERGE_REQUEST_NOTEABLE_TYPE });

        expect(findCloseReopenButton().text()).toBe('Close merge request');
      });

      describe('when clicking close/reopen button', () => {
        it('should show a loading spinner', async () => {
          mountComponent({
            noteableType: constants.MERGE_REQUEST_NOTEABLE_TYPE,
            mountFunction: mount,
          });

          await findCloseReopenButton().trigger('click');

          expect(findCloseReopenButton().props('loading')).toBe(true);
        });
      });

      describe('when toggling state', () => {
        describe('when issue', () => {
          it('emits event to toggle state', () => {
            mountComponent({ mountFunction: mount });

            jest.spyOn(eventHub, '$emit');

            findCloseReopenButton().trigger('click');

            expect(eventHub.$emit).toHaveBeenCalledWith('toggle.issuable.state');
          });
        });

        describe.each`
          type               | noteableType
          ${'merge request'} | ${'MergeRequest'}
          ${'epic'}          | ${'Epic'}
        `('when $type', ({ type, noteableType }) => {
          describe('when open', () => {
            it(`makes an API call to open it`, () => {
              mountComponent({
                noteableType,
                noteableData: { ...noteableDataMock, state: constants.OPENED },
                mountFunction: mount,
              });

              jest.spyOn(wrapper.vm, 'closeIssuable').mockResolvedValue();

              findCloseReopenButton().trigger('click');

              expect(wrapper.vm.closeIssuable).toHaveBeenCalled();
            });

            it(`shows an error when the API call fails`, async () => {
              mountComponent({
                noteableType,
                noteableData: { ...noteableDataMock, state: constants.OPENED },
                mountFunction: mount,
              });

              jest.spyOn(wrapper.vm, 'closeIssuable').mockRejectedValue();

              await findCloseReopenButton().trigger('click');

              await wrapper.vm.$nextTick;
              await wrapper.vm.$nextTick;

              expect(createFlash).toHaveBeenCalledWith({
                message: `Something went wrong while closing the ${type}. Please try again later.`,
              });
            });
          });

          describe('when closed', () => {
            it('makes an API call to close it', () => {
              mountComponent({
                noteableType,
                noteableData: { ...noteableDataMock, state: constants.CLOSED },
                mountFunction: mount,
              });

              jest.spyOn(wrapper.vm, 'reopenIssuable').mockResolvedValue();

              findCloseReopenButton().trigger('click');

              expect(wrapper.vm.reopenIssuable).toHaveBeenCalled();
            });
          });

          it(`shows an error when the API call fails`, async () => {
            mountComponent({
              noteableType,
              noteableData: { ...noteableDataMock, state: constants.CLOSED },
              mountFunction: mount,
            });

            jest.spyOn(wrapper.vm, 'reopenIssuable').mockRejectedValue();

            await findCloseReopenButton().trigger('click');

            await wrapper.vm.$nextTick;
            await wrapper.vm.$nextTick;

            expect(createFlash).toHaveBeenCalledWith({
              message: `Something went wrong while reopening the ${type}. Please try again later.`,
            });
          });
        });

        it('when merge request, should update MR count', async () => {
          mountComponent({
            noteableType: constants.MERGE_REQUEST_NOTEABLE_TYPE,
            mountFunction: mount,
          });

          jest.spyOn(wrapper.vm, 'closeIssuable').mockResolvedValue();

          await findCloseReopenButton().trigger('click');

          await wrapper.vm.$nextTick();

          expect(refreshUserMergeRequestCounts).toHaveBeenCalled();
        });
      });
    });

    describe('confidential notes checkbox', () => {
      describe('when confidentialNotes feature flag is `false`', () => {
        const features = { confidentialNotes: false };

        it('should not render checkbox', () => {
          mountComponent({
            mountFunction: mount,
            initialData: { note: 'confidential note' },
            noteableData: { ...notableDataMockCanUpdateIssuable },
            features,
          });

          const checkbox = findConfidentialNoteCheckbox();
          expect(checkbox.exists()).toBe(false);
        });
      });

      describe('when confidentialNotes feature flag is `true`', () => {
        const features = { confidentialNotes: true };

        it('should render checkbox as unchecked by default', () => {
          mountComponent({
            mountFunction: mount,
            initialData: { note: 'confidential note' },
            noteableData: { ...notableDataMockCanUpdateIssuable },
            features,
          });

          const checkbox = findConfidentialNoteCheckbox();
          expect(checkbox.exists()).toBe(true);
          expect(checkbox.element.checked).toBe(false);
        });

        describe.each`
          shouldCheckboxBeChecked
          ${true}
          ${false}
        `('when checkbox value is `$shouldCheckboxBeChecked`', ({ shouldCheckboxBeChecked }) => {
          it(`sets \`confidential\` to \`${shouldCheckboxBeChecked}\``, async () => {
            mountComponent({
              mountFunction: mount,
              initialData: { note: 'confidential note' },
              noteableData: { ...notableDataMockCanUpdateIssuable },
              features,
            });

            jest.spyOn(wrapper.vm, 'saveNote').mockResolvedValue({});

            const checkbox = findConfidentialNoteCheckbox();

            // check checkbox
            checkbox.element.checked = shouldCheckboxBeChecked;
            checkbox.trigger('change');
            await wrapper.vm.$nextTick();

            // submit comment
            findCommentButton().trigger('click');

            const [providedData] = wrapper.vm.saveNote.mock.calls[0];
            expect(providedData.data.note.confidential).toBe(shouldCheckboxBeChecked);
          });
        });

        describe('when user cannot update issuable', () => {
          it('should not render checkbox', () => {
            mountComponent({
              mountFunction: mount,
              noteableData: { ...notableDataMockCannotUpdateIssuable },
              features,
            });

            expect(findConfidentialNoteCheckbox().exists()).toBe(false);
          });
        });
      });
    });
  });

  describe('user is not logged in', () => {
    beforeEach(() => {
      mountComponent({ userData: null, noteableData: loggedOutnoteableData, mountFunction: mount });
    });

    it('should render signed out widget', () => {
      expect(wrapper.text()).toBe('Please register or sign in to reply');
    });

    it('should not render submission form', () => {
      expect(findTextArea().exists()).toBe(false);
    });
  });

  describe('with batchComments in store', () => {
    beforeEach(() => {
      store.registerModule('batchComments', batchComments());
    });

    describe('add to review and comment now buttons', () => {
      it('when no drafts exist, should not render', () => {
        mountComponent();

        expect(findCommentGlDropdown().exists()).toBe(true);
        expect(findAddToReviewButton().exists()).toBe(false);
        expect(findAddCommentNowButton().exists()).toBe(false);
      });

      describe('when drafts exist', () => {
        beforeEach(() => {
          store.state.batchComments.drafts = [{ note: 'A' }];
        });

        it('should render', () => {
          mountComponent();

          expect(findCommentGlDropdown().exists()).toBe(false);
          expect(findAddToReviewButton().exists()).toBe(true);
          expect(findAddCommentNowButton().exists()).toBe(true);
        });

        it('clicking `add to review`, should call draft endpoint, set `isDraft` true', () => {
          mountComponent({ mountFunction: mount, initialData: { note: 'a draft note' } });

          jest.spyOn(store, 'dispatch').mockResolvedValue();
          findAddToReviewButton().trigger('click');

          expect(store.dispatch).toHaveBeenCalledWith(
            'saveNote',
            expect.objectContaining({
              endpoint: notesDataMock.draftsPath,
              isDraft: true,
            }),
          );
        });

        it('clicking `add comment now`, should call note endpoint, set `isDraft` false ', () => {
          mountComponent({ mountFunction: mount, initialData: { note: 'a comment' } });

          jest.spyOn(store, 'dispatch').mockResolvedValue();
          findAddCommentNowButton().trigger('click');

          expect(store.dispatch).toHaveBeenCalledWith(
            'saveNote',
            expect.objectContaining({
              endpoint: noteableDataMock.create_note_path,
              isDraft: false,
            }),
          );
        });
      });
    });
  });
});
