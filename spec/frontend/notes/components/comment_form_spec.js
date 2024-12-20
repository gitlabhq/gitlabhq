import { GlAlert } from '@gitlab/ui';
import Autosize from 'autosize';
import MockAdapter from 'axios-mock-adapter';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import waitForPromises from 'helpers/wait_for_promises';
import {
  extendedWrapper,
  mountExtended,
  shallowMountExtended,
} from 'helpers/vue_test_utils_helper';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import batchComments from '~/batch_comments/stores/modules/batch_comments';
import { fetchUserCounts } from '~/super_sidebar/user_counts_fetch';
import { createAlert } from '~/alert';
import { STATUS_CLOSED, STATUS_OPEN } from '~/issues/constants';
import axios from '~/lib/utils/axios_utils';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { HTTP_STATUS_UNPROCESSABLE_ENTITY } from '~/lib/utils/http_status';
import CommentForm from '~/notes/components/comment_form.vue';
import * as constants from '~/notes/constants';
import eventHub from '~/notes/event_hub';
import { COMMENT_FORM } from '~/notes/i18n';
import notesModule from '~/notes/stores/modules';
import { sprintf } from '~/locale';
import { mockTracking } from 'helpers/tracking_helper';
import { detectAndConfirmSensitiveTokens } from '~/lib/utils/secret_detection';
import { loggedOutnoteableData, notesDataMock, userDataMock, noteableDataMock } from '../mock_data';

jest.mock('autosize');
jest.mock('~/super_sidebar/user_counts_fetch');
jest.mock('~/alert');
jest.mock('~/lib/utils/secret_detection', () => {
  return {
    detectAndConfirmSensitiveTokens: jest.fn(() => Promise.resolve(true)),
  };
});

Vue.use(Vuex);

describe('issue_comment_form component', () => {
  useLocalStorageSpy();

  let trackingSpy;
  let wrapper;
  let axiosMock;

  const findCloseReopenButton = () => wrapper.findByTestId('close-reopen-button');
  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);
  const findMarkdownEditorTextarea = () => findMarkdownEditor().find('textarea');
  const findStartReviewButton = () => wrapper.findByTestId('start-review-button');
  const findAddToReviewButton = () => wrapper.findByTestId('add-to-review-button');
  const findAddCommentNowButton = () => wrapper.findByTestId('add-comment-now-button');
  const findConfidentialNoteCheckbox = () => wrapper.findByTestId('internal-note-checkbox');
  const findInternalNoteTooltipIcon = () => wrapper.findByTestId('question-o-icon');
  const findCommentTypeDropdown = () => wrapper.findByTestId('comment-button');
  const findCommentButton = () => findCommentTypeDropdown().find('button');
  const findErrorAlerts = () => wrapper.findAllComponents(GlAlert).wrappers;

  const createStore = ({ actions = { saveNote: jest.fn() }, state = {}, getters = {} } = {}) => {
    const baseModule = notesModule();

    return new Vuex.Store({
      ...baseModule,
      actions: {
        ...baseModule.actions,
        ...actions,
      },
      state: {
        ...baseModule.state,
        ...state,
      },
      getters: {
        ...baseModule.getters,
        ...getters,
      },
    });
  };

  const createNotableDataMock = (data = {}) => {
    return {
      ...noteableDataMock,
      ...data,
    };
  };

  const notableDataMockCanUpdateIssuable = createNotableDataMock({
    current_user: { can_update: true, can_create_note: true, can_create_confidential_note: true },
  });

  const notableDataMockCannotUpdateIssuable = createNotableDataMock({
    current_user: {
      can_update: false,
      can_create_note: false,
      can_create_confidential_note: false,
    },
  });

  const notableDataMockCannotCreateConfidentialNote = createNotableDataMock({
    current_user: { can_update: false, can_create_note: true, can_create_confidential_note: false },
  });

  const mountComponent = ({
    initialData = {},
    noteableType = 'Issue',
    noteableData = noteableDataMock,
    notesData = notesDataMock,
    userData = userDataMock,
    features = {},
    mountFunction = shallowMountExtended,
    store = createStore(),
    stubs = {},
  } = {}) => {
    store.dispatch('setNoteableData', noteableData);
    store.dispatch('setNotesData', notesData);
    store.dispatch('setUserData', userData);

    wrapper = mountFunction(CommentForm, {
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
      stubs,
    });
  };

  beforeEach(() => {
    axiosMock = new MockAdapter(axios);
    trackingSpy = mockTracking(undefined, null, jest.spyOn);
    detectAndConfirmSensitiveTokens.mockReturnValue(true);
  });

  afterEach(() => {
    axiosMock.restore();
    detectAndConfirmSensitiveTokens.mockReset();
  });

  describe('user is logged in', () => {
    describe('handleSave', () => {
      const note = 'hello world';

      it('should request to save note when note is entered', async () => {
        const store = createStore();
        jest.spyOn(store, 'dispatch');
        mountComponent({ mountFunction: mountExtended, initialData: { note }, store });
        expect(findCloseReopenButton().props('disabled')).toBe(false);
        expect(findMarkdownEditor().props('value')).toBe(note);
        await findCloseReopenButton().trigger('click');
        expect(findCloseReopenButton().props('disabled')).toBe(true);
        expect(findMarkdownEditor().props('value')).toBe('');
        expect(store.dispatch).toHaveBeenLastCalledWith('saveNote', expect.objectContaining({}));
      });

      it('tracks event', async () => {
        const store = createStore();
        mountComponent({ mountFunction: mountExtended, initialData: { note }, store });
        await findCloseReopenButton().trigger('click');
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'save_markdown', {
          label: 'markdown_editor',
          property: 'Issue_comment',
        });
      });

      it('does not report errors in the UI when the save succeeds', async () => {
        const store = createStore();
        mountComponent({
          mountFunction: mountExtended,
          initialData: { note: '/label ~sdfghj' },
          store,
        });
        await findCommentButton().trigger('click');
        // findErrorAlerts().exists returns false if *any* wrapper is empty,
        //   not necessarily that there aren't any at all.
        // We want to check here that there are none found, so we use the
        //   raw wrapper array length instead.
        expect(findErrorAlerts().length).toBe(0);
      });

      it.each`
        httpStatus                          | errors
        ${400}                              | ${[COMMENT_FORM.GENERIC_UNSUBMITTABLE_NETWORK]}
        ${HTTP_STATUS_UNPROCESSABLE_ENTITY} | ${['error 1']}
        ${HTTP_STATUS_UNPROCESSABLE_ENTITY} | ${['error 1', 'error 2']}
        ${HTTP_STATUS_UNPROCESSABLE_ENTITY} | ${['error 1', 'error 2', 'error 3']}
      `(
        'displays the correct errors ($errors) for a $httpStatus network response',
        async ({ errors, httpStatus }) => {
          const store = createStore({
            actions: {
              saveNote: jest.fn().mockRejectedValue({
                response: {
                  status: httpStatus,
                  data: { quick_actions_status: { error_messages: errors } },
                },
              }),
            },
          });
          mountComponent({
            mountFunction: mountExtended,
            initialData: { note: '/label ~sdfghj' },
            store,
          });
          await findCommentButton().trigger('click');
          await waitForPromises();
          const errorAlerts = findErrorAlerts();
          expect(errorAlerts.length).toBe(errors.length);
          errors.forEach((msg, index) => {
            const alert = errorAlerts[index];

            expect(alert.text()).toBe(msg);
          });
        },
      );

      describe('if response contains validation errors', () => {
        beforeEach(async () => {
          const store = createStore({
            actions: {
              saveNote: jest.fn().mockRejectedValue({
                response: {
                  status: HTTP_STATUS_UNPROCESSABLE_ENTITY,
                  data: { errors: 'error 1 and error 2' },
                },
              }),
            },
          });

          mountComponent({
            mountFunction: mountExtended,
            initialData: { note: 'invalid note' },
            store,
          });

          findCommentButton().trigger('click');
          await waitForPromises();
        });

        it('renders an error message', () => {
          const errorAlerts = findErrorAlerts();

          expect(errorAlerts.length).toBe(1);

          expect(errorAlerts[0].text()).toBe(
            sprintf(COMMENT_FORM.error, { reason: 'error 1 and error 2' }),
          );
        });
      });

      it('should remove the correct error from the list when it is dismissed', async () => {
        const commandErrors = ['1', '2', '3'];
        const store = createStore({
          actions: {
            saveNote: jest.fn().mockRejectedValue({
              response: {
                status: HTTP_STATUS_UNPROCESSABLE_ENTITY,
                data: { quick_actions_status: { error_messages: [...commandErrors] } },
              },
            }),
          },
        });
        mountComponent({
          mountFunction: mountExtended,
          initialData: { note: '/label ~sdfghj' },
          store,
        });
        await findCommentButton().trigger('click');
        await waitForPromises();

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

      it('should toggle issue state when no note', async () => {
        mountComponent({ mountFunction: mountExtended });
        jest.spyOn(eventHub, '$emit');
        expect(eventHub.$emit).not.toHaveBeenCalledWith('toggle.issuable.state');
        await findCloseReopenButton().trigger('click');
        expect(eventHub.$emit).toHaveBeenCalledWith('toggle.issuable.state');
      });

      it('should disable action button while submitting', async () => {
        const store = createStore({
          actions: {
            saveNote: jest.fn().mockReturnValue(),
          },
        });
        mountComponent({
          mountFunction: mountExtended,
          initialData: { note: 'hello world' },
          store,
        });
        const actionButton = findCloseReopenButton();
        await actionButton.trigger('click');
        expect(actionButton.props('disabled')).toBe(true);
        await waitForPromises();
        await nextTick();
        expect(actionButton.props('disabled')).toBe(false);
      });
    });

    it('shows content editor switcher', () => {
      mountComponent({ mountFunction: mountExtended });
      expect(wrapper.text()).toContain('Switch to rich text editing');
    });

    describe('textarea', () => {
      describe('general', () => {
        it.each`
          noteType           | noteIsInternal | placeholder
          ${'comment'}       | ${false}       | ${'Write a comment or drag your files here…'}
          ${'internal note'} | ${true}        | ${'Write an internal note or drag your files here…'}
        `(
          'should render textarea with placeholder for $noteType',
          async ({ noteIsInternal, placeholder }) => {
            await mountComponent();
            await findConfidentialNoteCheckbox().vm.$emit('input', noteIsInternal);
            expect(findMarkdownEditor().props('formFieldProps').placeholder).toBe(placeholder);
          },
        );

        it('should make textarea disabled while requesting', async () => {
          mountComponent({ mountFunction: mountExtended });
          findMarkdownEditor().vm.$emit('input', 'hello world');
          await nextTick();
          await findCommentButton().trigger('click');
          expect(findMarkdownEditor().find('textarea').attributes('disabled')).toBeDefined();
        });

        it('should support quick actions and other props', () => {
          mountComponent({ mountFunction: mountExtended });

          expect(findMarkdownEditor().props()).toMatchObject({
            supportsQuickActions: true,
            noteableType: noteableDataMock.noteableType,
          });
        });

        it('should link to markdown docs', () => {
          mountComponent({ mountFunction: mountExtended });

          const { markdownDocsPath } = notesDataMock;

          expect(wrapper.find(`[href="${markdownDocsPath}"]`).exists()).toBe(true);
        });

        it('should resize textarea after note is saved', async () => {
          const store = createStore();
          store.registerModule('batchComments', batchComments());
          store.state.batchComments.drafts = [{ note: 'A' }];
          await mountComponent({
            mountFunction: mountExtended,
            initialData: { note: 'foo' },
            store,
          });
          await findAddCommentNowButton().trigger('click');
          await waitForPromises();
          expect(Autosize.update).toHaveBeenCalled();
        });
      });

      describe('edit mode', () => {
        it('should enter edit mode when arrow up is pressed', async () => {
          const noteId = 2;
          const store = createStore({
            state: {
              discussions: [{ notes: [{ id: noteId, author: userDataMock }] }],
            },
          });
          mountComponent({ mountFunction: mountExtended, store });
          jest.spyOn(eventHub, '$emit');
          await findMarkdownEditorTextarea().trigger('keydown.up');
          expect(eventHub.$emit).toHaveBeenCalledWith('enterEditMode', { noteId });
        });

        describe('event enter', () => {
          describe('when no draft exists', () => {
            const store = createStore({ actions: {} });

            it('should save note when cmd+enter is pressed', async () => {
              mountComponent({ mountFunction: mountExtended, initialData: { note: 'a' }, store });
              jest.spyOn(axios, 'post');
              await findMarkdownEditorTextarea().trigger('keydown.enter', { metaKey: true });
              expect(axios.post).toHaveBeenCalledWith(noteableDataMock.create_note_path, {
                merge_request_diff_head_sha: undefined,
                note: {
                  internal: false,
                  note: 'a',
                  noteable_id: noteableDataMock.id,
                  noteable_type: 'Issue',
                },
              });
            });

            it('should save note when ctrl+enter is pressed', async () => {
              mountComponent({ mountFunction: mountExtended, initialData: { note: 'a' }, store });
              jest.spyOn(axios, 'post');
              await findMarkdownEditorTextarea().trigger('keydown.enter', { ctrlKey: true });
              expect(axios.post).toHaveBeenCalledWith(noteableDataMock.create_note_path, {
                merge_request_diff_head_sha: undefined,
                note: {
                  internal: false,
                  note: 'a',
                  noteable_id: noteableDataMock.id,
                  noteable_type: 'Issue',
                },
              });
            });
          });

          describe('when a draft exists', () => {
            let store;

            beforeEach(() => {
              store = createStore({
                actions: {
                  saveNote: jest.fn().mockResolvedValue(),
                },
              });
              store.registerModule('batchComments', batchComments());
              store.state.batchComments.drafts = [{ note: 'A' }];
            });

            it('sends the event to indicate that a new draft comment has been added', async () => {
              const note = 'some note text which enables actually adding a draft note';

              jest.spyOn(eventHub, '$emit');
              mountComponent({ mountFunction: mountExtended, initialData: { note }, store });

              findAddToReviewButton().trigger('click');

              await waitForPromises();

              expect(eventHub.$emit).toHaveBeenCalledWith('noteFormAddToReview', {
                name: 'noteFormAddToReview',
              });
            });

            it('should save note draft when cmd+enter is pressed', async () => {
              mountComponent({ mountFunction: mountExtended, initialData: { note: 'a' }, store });
              jest.spyOn(store, 'dispatch').mockResolvedValue();
              await findMarkdownEditorTextarea().trigger('keydown.enter', { metaKey: true });
              expect(store.dispatch).toHaveBeenCalledWith('saveNote', {
                data: {
                  merge_request_diff_head_sha: undefined,
                  note: {
                    internal: false,
                    note: 'a',
                    noteable_id: noteableDataMock.id,
                    noteable_type: 'Issue',
                    type: 'DiscussionNote',
                  },
                },
                endpoint: notesDataMock.draftsPath,
                flashContainer: expect.anything(),
                isDraft: true,
              });
            });

            it('should save note draft when ctrl+enter is pressed', async () => {
              mountComponent({ mountFunction: mountExtended, initialData: { note: 'a' }, store });
              jest.spyOn(store, 'dispatch').mockResolvedValue();
              await findMarkdownEditorTextarea().trigger('keydown.enter', { ctrlKey: true });
              expect(store.dispatch).toHaveBeenCalledWith('saveNote', {
                data: {
                  merge_request_diff_head_sha: undefined,
                  note: {
                    internal: false,
                    note: 'a',
                    noteable_id: noteableDataMock.id,
                    noteable_type: 'Issue',
                    type: 'DiscussionNote',
                  },
                },
                endpoint: notesDataMock.draftsPath,
                flashContainer: expect.anything(),
                isDraft: true,
              });
            });

            it('should add comment when shift+cmd+enter is pressed', async () => {
              mountComponent({ mountFunction: mountExtended, initialData: { note: 'a' }, store });
              jest.spyOn(store, 'dispatch').mockResolvedValue();
              await findMarkdownEditorTextarea().trigger('keydown.enter', {
                shiftKey: true,
                metaKey: true,
              });
              expect(store.dispatch).toHaveBeenCalledWith('saveNote', {
                data: {
                  merge_request_diff_head_sha: undefined,
                  note: {
                    internal: false,
                    note: 'a',
                    noteable_id: noteableDataMock.id,
                    noteable_type: 'Issue',
                  },
                },
                endpoint: noteableDataMock.create_note_path,
                flashContainer: expect.anything(),
                isDraft: false,
              });
            });

            it('should add comment when shift+ctrl+enter is pressed', async () => {
              mountComponent({ mountFunction: mountExtended, initialData: { note: 'a' }, store });
              jest.spyOn(store, 'dispatch').mockResolvedValue();
              await findMarkdownEditorTextarea().trigger('keydown.enter', {
                shiftKey: true,
                ctrlKey: true,
              });
              expect(store.dispatch).toHaveBeenCalledWith('saveNote', {
                data: {
                  merge_request_diff_head_sha: undefined,
                  note: {
                    internal: false,
                    note: 'a',
                    noteable_id: noteableDataMock.id,
                    noteable_type: 'Issue',
                  },
                },
                endpoint: noteableDataMock.create_note_path,
                flashContainer: expect.anything(),
                isDraft: false,
              });
            });
          });
        });
      });
    });

    describe('actions', () => {
      it('should be possible to close the issue', () => {
        mountComponent();

        expect(findCloseReopenButton().text()).toBe('Close issue');
      });

      it.each`
        noteIsInternal | buttonText
        ${false}       | ${'Comment'}
        ${true}        | ${'Add internal note'}
      `('renders comment button with text "$buttonText"', ({ noteIsInternal, buttonText }) => {
        mountComponent({
          mountFunction: mountExtended,
          noteableData: createNotableDataMock({ confidential: noteIsInternal }),
          initialData: { noteIsInternal },
        });

        expect(findCommentButton().text()).toBe(buttonText);
      });

      it('should render comment button as disabled', () => {
        mountComponent();

        expect(findCommentTypeDropdown().props('disabled')).toBe(true);
      });

      it('should enable comment button if it has note', async () => {
        mountComponent();

        findMarkdownEditor().vm.$emit('input', 'Foo');
        await nextTick();

        expect(findCommentTypeDropdown().props('disabled')).toBe(false);
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
            mountFunction: mountExtended,
          });

          await findCloseReopenButton().trigger('click');

          expect(findCloseReopenButton().props('loading')).toBe(true);
        });
      });

      describe('when toggling state', () => {
        describe('when issue', () => {
          it('emits event to toggle state', () => {
            mountComponent({ mountFunction: mountExtended });

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
            it(`makes an API call to close it`, () => {
              jest.spyOn(axios, 'put').mockResolvedValue({ data: {} });
              mountComponent({
                noteableType,
                noteableData: { ...noteableDataMock, state: STATUS_OPEN },
                mountFunction: mountExtended,
              });
              expect(axios.put).not.toHaveBeenCalledWith();
              findCloseReopenButton().trigger('click');
              expect(axios.put).toHaveBeenCalledWith(notesDataMock.closePath);
            });

            it(`shows an error when the API call fails`, async () => {
              jest.spyOn(axios, 'put').mockRejectedValue();
              mountComponent({
                noteableType,
                noteableData: { ...noteableDataMock, state: STATUS_OPEN },
                mountFunction: mountExtended,
              });
              await findCloseReopenButton().trigger('click');
              await nextTick();
              await nextTick();
              expect(createAlert).toHaveBeenCalledWith({
                message: `Something went wrong while closing the ${type}. Please try again later.`,
              });
            });
          });

          describe('when closed', () => {
            it('makes an API call to close it', () => {
              jest.spyOn(axios, 'put').mockResolvedValue({ data: {} });
              mountComponent({
                noteableType,
                noteableData: { ...noteableDataMock, state: STATUS_CLOSED },
                mountFunction: mountExtended,
              });

              expect(findCloseReopenButton().text()).toBe(`Reopen ${type}`);
              expect(axios.put).not.toHaveBeenCalled();
              findCloseReopenButton().trigger('click');
              expect(axios.put).toHaveBeenCalledWith(notesDataMock.reopenPath);
            });
          });

          it(`shows an error when the API call fails`, async () => {
            jest.spyOn(axios, 'put').mockRejectedValue();
            mountComponent({
              noteableType,
              noteableData: { ...noteableDataMock, state: STATUS_CLOSED },
              mountFunction: mountExtended,
            });
            await findCloseReopenButton().trigger('click');
            await nextTick();
            await nextTick();

            expect(createAlert).toHaveBeenCalledWith({
              message: `Something went wrong while reopening the ${type}. Please try again later.`,
            });
          });
        });

        it('when merge request, should update MR count', async () => {
          jest.spyOn(axios, 'put').mockResolvedValue({ data: {} });
          mountComponent({
            noteableType: constants.MERGE_REQUEST_NOTEABLE_TYPE,
            mountFunction: mountExtended,
          });
          await findCloseReopenButton().trigger('click');
          await waitForPromises();

          expect(axios.put).toHaveBeenCalledWith(notesDataMock.closePath);
          expect(fetchUserCounts).toHaveBeenCalled();
        });
      });
    });

    describe('confidential notes checkbox', () => {
      it('should render checkbox as unchecked by default', () => {
        mountComponent({
          mountFunction: mountExtended,
          initialData: { note: 'confidential note' },
          noteableData: { ...notableDataMockCanUpdateIssuable },
        });

        const checkbox = findConfidentialNoteCheckbox();
        expect(checkbox.exists()).toBe(true);
        expect(checkbox.element.checked).toBe(false);
      });

      it('renders checkbox when hasDrafts is true', () => {
        const store = createStore({ getters: { hasDrafts: () => true } });

        mountComponent({ store });

        expect(findConfidentialNoteCheckbox().exists()).toBe(true);
      });

      it('should not render checkbox if user is not at least a planner', () => {
        mountComponent({
          mountFunction: mountExtended,
          initialData: { note: 'confidential note' },
          noteableData: { ...notableDataMockCannotCreateConfidentialNote },
        });

        const checkbox = findConfidentialNoteCheckbox();
        expect(checkbox.exists()).toBe(false);
      });

      it('should have the tooltip explaining the internal note capabilities', () => {
        mountComponent({
          mountFunction: mountExtended,
          initialData: { note: 'confidential note' },
          noteableData: { ...notableDataMockCanUpdateIssuable },
        });

        const tooltip = findInternalNoteTooltipIcon();
        expect(tooltip.exists()).toBe(true);
        expect(tooltip.attributes('title')).toBe(COMMENT_FORM.internalVisibility);
      });

      it.each`
        noteableType      | rendered | message
        ${'Issue'}        | ${true}  | ${'render'}
        ${'Epic'}         | ${true}  | ${'render'}
        ${'MergeRequest'} | ${true}  | ${'render'}
      `(
        'should $message checkbox when noteableType is $noteableType',
        ({ noteableType, rendered }) => {
          mountComponent({
            mountFunction: mountExtended,
            noteableType,
            initialData: { note: 'internal note' },
            noteableData: { ...notableDataMockCanUpdateIssuable, noteableType },
          });

          expect(findConfidentialNoteCheckbox().exists()).toBe(rendered);
        },
      );

      describe.each`
        shouldCheckboxBeChecked
        ${true}
        ${false}
      `('when checkbox value is `$shouldCheckboxBeChecked`', ({ shouldCheckboxBeChecked }) => {
        it(`sets \`internal\` to \`${shouldCheckboxBeChecked}\``, async () => {
          const store = createStore();
          const note = 'internal note';
          mountComponent({
            mountFunction: mountExtended,
            initialData: { note },
            noteableData: { ...notableDataMockCanUpdateIssuable },
            store,
          });

          jest.spyOn(store, 'dispatch');
          const checkbox = findConfidentialNoteCheckbox();

          // check checkbox
          checkbox.element.checked = shouldCheckboxBeChecked;
          checkbox.trigger('change');
          await nextTick();

          // submit comment
          findCommentButton().trigger('click');
          await waitForPromises();

          expect(store.dispatch).toHaveBeenCalledWith('saveNote', {
            data: {
              merge_request_diff_head_sha: undefined,
              note: {
                internal: shouldCheckboxBeChecked,
                note,
                noteable_id: noteableDataMock.id,
                noteable_type: 'Issue',
              },
            },
            endpoint: noteableDataMock.create_note_path,
            flashContainer: expect.anything(),
            isDraft: false,
          });
        });
      });

      describe('when user cannot update issuable', () => {
        it('should not render checkbox', () => {
          mountComponent({
            mountFunction: mountExtended,
            noteableData: { ...notableDataMockCannotUpdateIssuable },
          });

          expect(findConfidentialNoteCheckbox().exists()).toBe(false);
        });
      });
    });
  });

  describe('check sensitive tokens', () => {
    const sensitiveMessage = 'token: glpat-1234567890abcdefghij';
    const nonSensitiveMessage = 'text';
    const store = createStore();

    it('should not save note when it contains sensitive token', async () => {
      detectAndConfirmSensitiveTokens.mockReturnValue(false);
      mountComponent({
        mountFunction: mountExtended,
        initialData: { note: sensitiveMessage },
        store,
      });
      jest.spyOn(store, 'dispatch');
      findCommentButton().trigger('click');
      await waitForPromises();
      expect(store.dispatch).not.toHaveBeenCalled();
    });

    it('should save note it does not contain sensitive token', async () => {
      mountComponent({
        mountFunction: mountExtended,
        initialData: { note: nonSensitiveMessage },
        store,
      });
      jest.spyOn(store, 'dispatch');
      await findCommentButton().trigger('click');
      await waitForPromises();
      expect(store.dispatch).toHaveBeenCalledWith('saveNote', expect.objectContaining({}));
    });
  });

  describe('user is not logged in', () => {
    beforeEach(() => {
      mountComponent({
        userData: null,
        noteableData: loggedOutnoteableData,
        mountFunction: mountExtended,
      });
    });

    it('should render signed out widget', () => {
      expect(wrapper.text()).toBe('Please register or sign in to reply');
    });

    it('should not render submission form', () => {
      expect(findMarkdownEditor().exists()).toBe(false);
    });
  });

  describe('with batchComments in store', () => {
    describe('start review, add to review and comment now buttons', () => {
      let store;

      beforeEach(() => {
        store = createStore();
        store.registerModule('batchComments', batchComments());
      });

      it('when no drafts exist on non-merge request, should not render', () => {
        mountComponent({ store });
        expect(findCommentTypeDropdown().exists()).toBe(true);
        expect(findStartReviewButton().exists()).toBe(false);
        expect(findAddToReviewButton().exists()).toBe(false);
        expect(findAddCommentNowButton().exists()).toBe(false);
      });

      it('when no drafts exist in a merge request, should render', () => {
        mountComponent({ noteableType: constants.MERGE_REQUEST_NOTEABLE_TYPE, store });
        expect(findCommentTypeDropdown().exists()).toBe(true);
        expect(findStartReviewButton().exists()).toBe(true);
        expect(findAddToReviewButton().exists()).toBe(false);
        expect(findAddCommentNowButton().exists()).toBe(false);
      });

      describe('when drafts exist', () => {
        beforeEach(() => {
          store.state.batchComments.drafts = [{ note: 'A' }];
        });

        it('should render proper action elements', async () => {
          await mountComponent({ store });
          expect(findCommentTypeDropdown().exists()).toBe(false);
          expect(findAddToReviewButton().exists()).toBe(true);
          expect(findAddCommentNowButton().exists()).toBe(true);
          expect(findStartReviewButton().exists()).toBe(false);
        });

        it('clicking `add to review`, should call draft endpoint, set `isDraft` true', async () => {
          mountComponent({
            mountFunction: mountExtended,
            initialData: { note: 'a draft note' },
            store,
          });
          jest.spyOn(store, 'dispatch').mockResolvedValue();
          await findAddToReviewButton().trigger('click');
          expect(store.dispatch).toHaveBeenCalledWith(
            'saveNote',
            expect.objectContaining({
              endpoint: notesDataMock.draftsPath,
              isDraft: true,
            }),
          );
        });

        it('clicking `add comment/thread now`, should call note endpoint, set `isDraft` false', async () => {
          await mountComponent({
            mountFunction: mountExtended,
            initialData: { note: 'a comment' },
            store,
          });
          jest.spyOn(store, 'dispatch').mockResolvedValue();
          await findAddCommentNowButton().trigger('click');
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

  it('calls append on a markdown editor', () => {
    mountComponent({ stubs: { MarkdownEditor } });
    const spy = jest.spyOn(findMarkdownEditor().vm, 'append');
    wrapper.vm.append('foo');
    expect(spy).toHaveBeenCalledWith('foo');
  });
});
