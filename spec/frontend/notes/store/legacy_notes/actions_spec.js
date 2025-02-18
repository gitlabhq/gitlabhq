import AxiosMockAdapter from 'axios-mock-adapter';
import { createTestingPinia } from '@pinia/testing';
import { createPinia, setActivePinia } from 'pinia';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'spec/test_constants';
import actionCable from '~/actioncable_consumer';
import Api from '~/api';
import { createAlert } from '~/alert';
import toast from '~/vue_shared/plugins/global_toast';
import { EVENT_ISSUABLE_VUE_APP_CHANGE } from '~/issuable/constants';
import axios from '~/lib/utils/axios_utils';
import {
  HTTP_STATUS_OK,
  HTTP_STATUS_SERVICE_UNAVAILABLE,
  HTTP_STATUS_UNPROCESSABLE_ENTITY,
} from '~/lib/utils/http_status';
import * as notesConstants from '~/notes/constants';
import * as types from '~/notes/stores/mutation_types';
import * as utils from '~/notes/stores/utils';
import updateIssueLockMutation from '~/sidebar/queries/update_issue_lock.mutation.graphql';
import updateMergeRequestLockMutation from '~/sidebar/queries/update_merge_request_lock.mutation.graphql';
import promoteTimelineEvent from '~/notes/graphql/promote_timeline_event.mutation.graphql';
import mrWidgetEventHub from '~/vue_merge_request_widget/event_hub';
import notesEventHub from '~/notes/event_hub';
import { useLegacyDiffs } from '~/diffs/stores/legacy_diffs';
import { useNotes } from '~/notes/store/legacy_notes';
import { createCustomGetters, createTestPiniaAction } from 'helpers/pinia_helpers';
import { useBatchComments } from '~/batch_comments/store';
import { globalAccessorPlugin } from '~/pinia/plugins';
import {
  discussionMock,
  notesDataMock,
  userDataMock,
  noteableDataMock,
  individualNote,
  batchSuggestionsInfoMock,
} from '../../mock_data';

const TEST_ERROR_MESSAGE = 'Test error message';
const mockAlertDismiss = jest.fn();
jest.mock('~/alert', () => ({
  createAlert: jest.fn().mockImplementation(() => ({
    dismiss: mockAlertDismiss,
  })),
}));

jest.mock('~/vue_shared/plugins/global_toast');

describe('Actions Notes Store', () => {
  let getters = {};
  let store;
  let testAction;
  let axiosMock;

  beforeEach(() => {
    getters = {};
    setActivePinia(createPinia());
    createTestingPinia({
      stubActions: false,
      plugins: [
        createCustomGetters(() => ({
          legacyNotes: getters,
          batchComments: {},
          legacyDiffs: {},
        })),
        globalAccessorPlugin,
      ],
    });
    useLegacyDiffs();
    store = useNotes();
    testAction = createTestPiniaAction(store);
    axiosMock = new AxiosMockAdapter(axios);

    // This is necessary as we query Close issue button at the top of issue page when clicking bottom button
    setHTMLFixture(
      '<div class="detail-page-header-actions"><button class="btn-close btn-grouped"></button></div>',
    );
  });

  afterEach(() => {
    axiosMock.restore();
    resetHTMLFixture();

    window.gon = {};
  });

  describe('setNotesData', () => {
    it('should set received notes data', () => {
      return testAction(
        store.setNotesData,
        notesDataMock,
        { notesData: {} },
        [{ type: store[types.SET_NOTES_DATA], payload: notesDataMock }],
        [],
      );
    });
  });

  describe('setNoteableData', () => {
    it('should set received issue data', () => {
      return testAction(
        store.setNoteableData,
        noteableDataMock,
        { noteableData: {} },
        [{ type: store[types.SET_NOTEABLE_DATA], payload: noteableDataMock }],
        [],
      );
    });
  });

  describe('setUserData', () => {
    it('should set received user data', () => {
      return testAction(
        store.setUserData,
        userDataMock,
        { userData: {} },
        [{ type: store[types.SET_USER_DATA], payload: userDataMock }],
        [],
      );
    });
  });

  describe('setLastFetchedAt', () => {
    it('should set received timestamp', () => {
      return testAction(
        store.setLastFetchedAt,
        'timestamp',
        { lastFetchedAt: {} },
        [{ type: store[types.SET_LAST_FETCHED_AT], payload: 'timestamp' }],
        [],
      );
    });
  });

  describe('setInitialNotes', () => {
    it('should set initial notes', () => {
      return testAction(
        store.setInitialNotes,
        [individualNote],
        { notes: [] },
        [{ type: store[types.ADD_OR_UPDATE_DISCUSSIONS], payload: [individualNote] }],
        [],
      );
    });
  });

  describe('setTargetNoteHash', () => {
    it('should set target note hash', () => {
      return testAction(
        store.setTargetNoteHash,
        'hash',
        { notes: [] },
        [{ type: store[types.SET_TARGET_NOTE_HASH], payload: 'hash' }],
        [],
      );
    });
  });

  describe('toggleDiscussion', () => {
    it('should toggle discussion', () => {
      return testAction(
        store.toggleDiscussion,
        { discussionId: discussionMock.id },
        { discussions: [discussionMock] },
        [{ type: store[types.TOGGLE_DISCUSSION], payload: { discussionId: discussionMock.id } }],
        [],
      );
    });
  });

  describe('expandDiscussion', () => {
    it('should expand discussion', () => {
      const spy = jest.spyOn(useLegacyDiffs(), 'renderFileForDiscussionId');
      return testAction(
        store.expandDiscussion,
        { discussionId: discussionMock.id },
        { discussions: [discussionMock] },
        [{ type: store[types.EXPAND_DISCUSSION], payload: { discussionId: discussionMock.id } }],
        [{ type: spy, payload: discussionMock.id }],
      );
    });
  });

  describe('collapseDiscussion', () => {
    it('should commit collapse discussion', () => {
      return testAction(
        store.collapseDiscussion,
        { discussionId: discussionMock.id },
        { discussions: [discussionMock] },
        [{ type: store[types.COLLAPSE_DISCUSSION], payload: { discussionId: discussionMock.id } }],
        [],
      );
    });
  });

  describe('async methods', () => {
    describe('closeMergeRequest', () => {
      it('sets state as closed', async () => {
        const eventHandler = jest.fn();
        document.addEventListener(EVENT_ISSUABLE_VUE_APP_CHANGE, eventHandler);

        const data = { foo: 1 };
        axiosMock.onPut('/close').replyOnce(HTTP_STATUS_OK, data);
        store.notesData.closePath = '/close';

        await store.closeIssuable();

        document.removeEventListener(EVENT_ISSUABLE_VUE_APP_CHANGE, eventHandler);

        expect(store.noteableData.state).toEqual('closed');
        expect(store.isToggleStateButtonLoading).toEqual(false);
        expect(eventHandler.mock.calls[0][0].detail).toStrictEqual({
          data,
          isClosed: true,
        });
      });
    });

    describe('reopenMergeRequest', () => {
      it('sets state as reopened', async () => {
        const eventHandler = jest.fn();
        document.addEventListener(EVENT_ISSUABLE_VUE_APP_CHANGE, eventHandler);

        const data = { foo: 1 };
        axiosMock.onPut('/reopen').replyOnce(HTTP_STATUS_OK, data);
        store.notesData.reopenPath = '/reopen';

        await store.reopenIssuable();

        document.removeEventListener(EVENT_ISSUABLE_VUE_APP_CHANGE, eventHandler);

        expect(store.noteableData.state).toEqual('reopened');
        expect(store.isToggleStateButtonLoading).toEqual(false);
        expect(eventHandler.mock.calls[0][0].detail).toStrictEqual({
          data,
          isClosed: false,
        });
      });
    });
  });

  describe('emitStateChangedEvent', () => {
    it('emits an event on the document', () => {
      document.addEventListener(EVENT_ISSUABLE_VUE_APP_CHANGE, (event) => {
        expect(event.detail.data).toEqual({ id: '1', state: 'closed' });
        expect(event.detail.isClosed).toEqual(false);
      });

      store.emitStateChangedEvent({ id: '1', state: 'closed' });
    });
  });

  describe('toggleStateButtonLoading', () => {
    it('should set loading as true', () => {
      return testAction(
        store.toggleStateButtonLoading,
        true,
        {},
        [{ type: store[types.TOGGLE_STATE_BUTTON_LOADING], payload: true }],
        [],
      );
    });

    it('should set loading as false', () => {
      return testAction(
        store.toggleStateButtonLoading,
        false,
        {},
        [{ type: store[types.TOGGLE_STATE_BUTTON_LOADING], payload: false }],
        [],
      );
    });
  });

  describe('toggleIssueLocalState', () => {
    it('sets issue state as closed', () => {
      return testAction(
        store.toggleIssueLocalState,
        'closed',
        {},
        [{ type: store[types.CLOSE_ISSUE] }],
        [],
      );
    });

    it('sets issue state as reopened', () => {
      return testAction(
        store.toggleIssueLocalState,
        'reopened',
        {},
        [{ type: store[types.REOPEN_ISSUE] }],
        [],
      );
    });
  });

  describe('initPolling', () => {
    beforeAll(() => {
      global.JEST_DEBOUNCE_THROTTLE_TIMEOUT = 100;
    });

    afterAll(() => {
      global.JEST_DEBOUNCE_THROTTLE_TIMEOUT = undefined;
    });

    const notesChannelParams = () => ({
      channel: 'Noteable::NotesChannel',
      project_id: store.notesData.projectId,
      group_id: store.notesData.groupId,
      noteable_type: store.notesData.noteableType,
      noteable_id: store.notesData.noteableId,
    });

    const notifyNotesChannel = () => {
      actionCable.subscriptions.notify(JSON.stringify(notesChannelParams()), 'received', {
        event: 'updated',
      });
    };

    it('creates the Action Cable subscription', () => {
      jest.spyOn(actionCable.subscriptions, 'create');

      store.setNotesData(notesDataMock);
      store.initPolling();

      expect(actionCable.subscriptions.create).toHaveBeenCalledTimes(1);
      expect(actionCable.subscriptions.create).toHaveBeenCalledWith(
        notesChannelParams(),
        expect.any(Object),
      );
    });

    it('prevents `fetchUpdatedNotes` being called multiple times within time limit when action cable receives contineously new events', () => {
      store.fetchUpdatedNotes.mockResolvedValue();
      getters = { getNotesDataByProp: () => 123456789 };

      store.setNotesData(notesDataMock);
      store.initPolling();

      notifyNotesChannel();
      notifyNotesChannel();
      notifyNotesChannel();

      jest.runOnlyPendingTimers();

      expect(store.fetchUpdatedNotes).toHaveBeenCalledTimes(1);
    });
  });

  describe('fetchUpdatedNotes', () => {
    const response = { notes: [], last_fetched_at: '123456' };
    const successMock = () =>
      axiosMock.onGet(notesDataMock.notesPath).reply(HTTP_STATUS_OK, response);

    beforeEach(() => {
      return store.setNotesData(notesDataMock);
    });

    it('calls the endpoint and stores last fetched state', async () => {
      successMock();

      await store.fetchUpdatedNotes();

      expect(store.lastFetchedAt).toBe('123456');
    });
  });

  describe('setNotesFetchedState', () => {
    it('should set notes fetched state', () => {
      return testAction(
        store.setNotesFetchedState,
        true,
        {},
        [{ type: store[types.SET_NOTES_FETCHED_STATE], payload: true }],
        [],
      );
    });
  });

  describe('removeNote', () => {
    const endpoint = `${TEST_HOST}/note`;

    beforeEach(() => {
      axiosMock.onDelete(endpoint).replyOnce(HTTP_STATUS_OK, {});

      document.body.dataset.page = '';
    });

    afterEach(() => {
      axiosMock.restore();

      document.body.dataset.page = '';
    });

    it('commits DELETE_NOTE and dispatches updateMergeRequestWidget', () => {
      const note = { path: endpoint, id: 1, discussion_id: 1, individual_note: true };

      return testAction(
        store.removeNote,
        note,
        { discussions: [note] },
        [
          {
            type: store[types.DELETE_NOTE],
            payload: note,
          },
        ],
        [
          {
            type: store.updateMergeRequestWidget,
          },
          {
            type: store.updateResolvableDiscussionsCounts,
          },
        ],
      );
    });

    it('dispatches removeDiscussionsFromDiff on merge request page', () => {
      const note = { path: endpoint, id: 1, discussion_id: 1, individual_note: true };
      const spy = jest.spyOn(useLegacyDiffs(), 'removeDiscussionsFromDiff');

      document.body.dataset.page = 'projects:merge_requests:show';

      return testAction(
        store.removeNote,
        note,
        { discussions: [note] },
        [
          {
            type: store[types.DELETE_NOTE],
            payload: note,
          },
        ],
        [
          {
            type: store.updateMergeRequestWidget,
          },
          {
            type: store.updateResolvableDiscussionsCounts,
          },
          {
            type: spy,
          },
        ],
      );
    });
  });

  describe('deleteNote', () => {
    const endpoint = `${TEST_HOST}/note`;

    beforeEach(() => {
      axiosMock.onDelete(endpoint).replyOnce(HTTP_STATUS_OK, {});

      document.body.dataset.page = '';
    });

    afterEach(() => {
      axiosMock.restore();

      document.body.dataset.page = '';
    });

    it('dispatches removeNote', () => {
      const note = { path: endpoint, id: 1, discussion_id: 1, individual_note: true };

      return testAction(
        store.deleteNote,
        note,
        { discussions: [note] },
        [],
        [
          {
            type: store.removeNote,
            payload: note,
          },
        ],
      );
    });
  });

  describe('createNewNote', () => {
    describe('success', () => {
      const res = {
        id: 1,
        valid: true,
      };

      beforeEach(() => {
        axiosMock.onAny().reply(HTTP_STATUS_OK, res);
      });

      it('commits ADD_NEW_NOTE and dispatches updateMergeRequestWidget', () => {
        return testAction(
          store.createNewNote,
          { endpoint: `${TEST_HOST}`, data: {} },
          store.state,
          [
            {
              type: store[types.ADD_NEW_NOTE],
              payload: res,
            },
          ],
          [
            {
              type: store.updateMergeRequestWidget,
            },
            {
              type: store.startTaskList,
            },
            {
              type: store.updateResolvableDiscussionsCounts,
            },
          ],
        );
      });
    });

    describe('error', () => {
      const res = {
        errors: ['error'],
      };

      beforeEach(() => {
        axiosMock.onAny().replyOnce(HTTP_STATUS_OK, res);
      });

      it('does not commit ADD_NEW_NOTE or dispatch updateMergeRequestWidget', () => {
        return testAction(
          store.createNewNote,
          { endpoint: `${TEST_HOST}`, data: {} },
          store.state,
          [],
          [],
        );
      });
    });
  });

  describe('toggleResolveNote', () => {
    const res = {
      resolved: true,
      expanded: true,
      discussion_id: 1,
      id: 1,
    };

    beforeEach(() => {
      axiosMock.onAny().reply(HTTP_STATUS_OK, res);
    });

    describe('as note', () => {
      it('commits UPDATE_NOTE and dispatches updateMergeRequestWidget', () => {
        return testAction(
          store.toggleResolveNote,
          { endpoint: `${TEST_HOST}`, isResolved: true, discussion: false },
          {
            discussions: [
              { resolved: false, discussion_id: 1, id: 1, individual_note: true, notes: [] },
            ],
          },
          [
            {
              type: store[types.UPDATE_NOTE],
              payload: res,
            },
          ],
          [
            {
              type: store.updateResolvableDiscussionsCounts,
            },
            {
              type: store.updateMergeRequestWidget,
            },
          ],
        );
      });
    });

    describe('as discussion', () => {
      it('commits UPDATE_DISCUSSION and dispatches updateMergeRequestWidget', () => {
        return testAction(
          store.toggleResolveNote,
          { endpoint: `${TEST_HOST}`, isResolved: true, discussion: true },
          {
            discussions: [
              { resolved: false, discussion_id: 1, id: 1, individual_note: true, notes: [] },
            ],
          },
          [
            {
              type: store[types.UPDATE_DISCUSSION],
              payload: res,
            },
          ],
          [
            {
              type: store.updateResolvableDiscussionsCounts,
            },
            {
              type: store.updateMergeRequestWidget,
            },
          ],
        );
      });
    });
  });

  describe('updateMergeRequestWidget', () => {
    it('calls mrWidget checkStatus', () => {
      jest.spyOn(mrWidgetEventHub, '$emit').mockImplementation(() => {});

      store.updateMergeRequestWidget();

      expect(mrWidgetEventHub.$emit).toHaveBeenCalledWith('mr.discussion.updated');
    });
  });

  describe('setCommentsDisabled', () => {
    it('should set comments disabled state', () => {
      return testAction(
        store.setCommentsDisabled,
        true,
        null,
        [{ type: store[types.DISABLE_COMMENTS], payload: true }],
        [],
      );
    });
  });

  describe('updateResolvableDiscussionsCounts', () => {
    it('commits UPDATE_RESOLVABLE_DISCUSSIONS_COUNTS', () => {
      return testAction(
        store.updateResolvableDiscussionsCounts,
        null,
        {},
        [{ type: store[types.UPDATE_RESOLVABLE_DISCUSSIONS_COUNTS] }],
        [],
      );
    });
  });

  describe('convertToDiscussion', () => {
    it('commits CONVERT_TO_DISCUSSION with noteId', () => {
      const noteId = 'dummy-note-id';
      return testAction(
        store.convertToDiscussion,
        noteId,
        {},
        [{ type: store[types.CONVERT_TO_DISCUSSION], payload: noteId }],
        [],
      );
    });
  });

  describe('updateOrCreateNotes', () => {
    beforeEach(() => {
      store.fetchDiscussions.mockResolvedValue();
    });

    it('Prevents `fetchDiscussions` being called multiple times within time limit', () => {
      const note = { id: 1234, type: notesConstants.DIFF_NOTE };
      getters = { notesById: {} };
      store.$patch({ discussions: [note], notesData: { discussionsPath: '' } });

      store.updateOrCreateNotes([note]);
      store.updateOrCreateNotes([note]);

      jest.runOnlyPendingTimers();

      store.updateOrCreateNotes([note]);

      expect(store.fetchDiscussions).toHaveBeenCalledTimes(2);
    });

    it('Updates existing note', () => {
      const note = { id: 1234 };
      store.discussions = [{ notes: [note] }];

      store.updateOrCreateNotes([note]);

      expect(store[types.UPDATE_NOTE]).toHaveBeenCalledWith(note);
    });

    it('Creates a new note if none exisits', () => {
      const note = { id: 1234 };

      store.updateOrCreateNotes([note]);

      expect(store[types.ADD_NEW_NOTE]).toHaveBeenCalledWith(note);
    });

    describe('Discussion notes', () => {
      let note;

      beforeEach(() => {
        note = { id: 1234, discussion_id: 1234 };
      });

      it('Adds a reply to an existing discussion', () => {
        store.discussions = [{ id: 1234, notes: [] }];
        const discussionNote = {
          ...note,
          type: notesConstants.DISCUSSION_NOTE,
          discussion_id: 1234,
        };

        store.updateOrCreateNotes([discussionNote]);

        expect(store[types.ADD_NEW_REPLY_TO_DISCUSSION]).toHaveBeenCalledWith(discussionNote);
      });

      it('fetches discussions for diff notes', () => {
        store.$patch({ discussions: [], notesData: { discussionsPath: 'Hello world' } });
        const diffNote = { ...note, type: notesConstants.DIFF_NOTE, discussion_id: 1234 };

        store.updateOrCreateNotes([diffNote]);

        expect(store.fetchDiscussions).toHaveBeenCalledWith({
          path: store.notesData.discussionsPath,
        });
      });

      it('Adds a new note', () => {
        store.discussions = [];
        const discussionNote = {
          ...note,
          type: notesConstants.DISCUSSION_NOTE,
          discussion_id: 1234,
        };

        store.updateOrCreateNotes([discussionNote]);

        expect(store[types.ADD_NEW_NOTE]).toHaveBeenCalledWith(discussionNote);
      });
    });
  });

  describe('replyToDiscussion', () => {
    const payload = { endpoint: TEST_HOST, data: {} };

    it('updates discussion if response contains discussion', () => {
      const discussion = { notes: [] };
      axiosMock.onAny().reply(HTTP_STATUS_OK, { discussion });

      return testAction(
        store.replyToDiscussion,
        payload,
        { discussions: [discussion] },
        [{ type: store[types.UPDATE_DISCUSSION], payload: discussion }],
        [
          { type: store.updateMergeRequestWidget },
          { type: store.startTaskList },
          { type: store.updateResolvableDiscussionsCounts },
        ],
      );
    });

    it('adds a reply to a discussion', () => {
      const res = {};
      axiosMock.onAny().reply(HTTP_STATUS_OK, res);

      return testAction(
        store.replyToDiscussion,
        payload,
        {},
        [{ type: store[types.ADD_NEW_REPLY_TO_DISCUSSION], payload: res }],
        [],
      );
    });
  });

  describe('removeConvertedDiscussion', () => {
    it('commits CONVERT_TO_DISCUSSION with noteId', () => {
      const noteId = 'dummy-id';
      return testAction(
        store.removeConvertedDiscussion,
        noteId,
        {},
        [{ type: store[types.REMOVE_CONVERTED_DISCUSSION], payload: noteId }],
        [],
      );
    });
  });

  describe('resolveDiscussion', () => {
    let discussionId;

    beforeEach(() => {
      discussionId = discussionMock.id;
      store.discussions = [discussionMock];
      getters = {
        isDiscussionResolved: () => false,
      };
    });

    it('when unresolved, dispatches action', () => {
      axiosMock.onAny().reply(HTTP_STATUS_OK, discussionMock);
      return testAction(
        store.resolveDiscussion,
        { discussionId },
        undefined,
        [],
        [
          {
            type: store.toggleResolveNote,
            payload: {
              endpoint: discussionMock.resolve_path,
              isResolved: false,
              discussion: true,
            },
          },
        ],
      );
    });

    it('when resolved, does nothing', () => {
      getters.isDiscussionResolved = (id) => id === discussionId;

      return testAction(store.resolveDiscussion, { discussionId }, undefined, [], []);
    });
  });

  describe('saveNote', () => {
    const flashContainer = {};
    const payload = { endpoint: TEST_HOST, data: { 'note[note]': 'some text' }, flashContainer };

    describe('if response contains errors', () => {
      const axiosError = { message: 'Unprocessable entity', errors: { something: ['went wrong'] } };

      it('throws an error', async () => {
        axiosMock.onAny().reply(HTTP_STATUS_UNPROCESSABLE_ENTITY, axiosError);
        try {
          await store.saveNote(payload);
        } catch (error) {
          expect(error.response.data.message).toBe(axiosError.message);
          expect(error.response.data.errors).toStrictEqual(axiosError.errors);
        }
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('if response contains no errors', () => {
      const res = { valid: true };

      it('returns the response', async () => {
        axiosMock.onAny().reply(HTTP_STATUS_OK, res);
        const data = await store.saveNote(payload);
        expect(data).toStrictEqual(res);
        expect(createAlert).not.toHaveBeenCalled();
      });

      it('dispatches clearDrafts is command names contains submit_review', async () => {
        const spy = jest.spyOn(useBatchComments(), 'clearDrafts');
        const response = {
          quick_actions_status: { command_names: ['submit_review'] },
          valid: true,
        };
        axiosMock.onAny().reply(HTTP_STATUS_OK, response);
        await store.saveNote(payload);

        expect(spy).toHaveBeenCalled();
        spy.mockReset();
      });
    });
  });

  describe('submitSuggestion', () => {
    const discussionId = 'discussion-id';
    const noteId = 'note-id';
    const suggestionId = 'suggestion-id';
    let flashContainer;

    beforeEach(() => {
      jest.spyOn(Api, 'applySuggestion').mockReturnValue(Promise.resolve());
      flashContainer = {};
    });

    const submitSuggestion = async () => {
      await store.submitSuggestion({ discussionId, noteId, suggestionId, flashContainer });
    };

    it('when service success, commits and resolves discussion', async () => {
      await submitSuggestion();
      expect(store[types.SET_RESOLVING_DISCUSSION]).toHaveBeenNthCalledWith(1, true);
      expect(store[types.SET_RESOLVING_DISCUSSION]).toHaveBeenNthCalledWith(2, false);
      expect(store.resolveDiscussion).toHaveBeenCalledWith({ discussionId });
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('when service fails, creates an alert with error message', async () => {
      const response = { response: { data: { message: TEST_ERROR_MESSAGE } } };

      Api.applySuggestion.mockReturnValue(Promise.reject(response));

      await submitSuggestion();
      expect(store[types.SET_RESOLVING_DISCUSSION]).toHaveBeenNthCalledWith(1, true);
      expect(store[types.SET_RESOLVING_DISCUSSION]).toHaveBeenNthCalledWith(2, false);
      expect(createAlert).toHaveBeenCalledWith({
        message: TEST_ERROR_MESSAGE,
        parent: flashContainer,
      });
    });

    it('when service fails, and no error message available, uses default message', async () => {
      const response = { response: 'foo' };

      Api.applySuggestion.mockReturnValue(Promise.reject(response));

      await submitSuggestion();
      expect(store[types.SET_RESOLVING_DISCUSSION]).toHaveBeenNthCalledWith(1, true);
      expect(store[types.SET_RESOLVING_DISCUSSION]).toHaveBeenNthCalledWith(2, false);
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while applying the suggestion. Please try again.',
        parent: flashContainer,
      });
    });

    it('when resolve discussion fails, fail gracefully', async () => {
      await submitSuggestion();
      expect(createAlert).not.toHaveBeenCalled();
    });
  });

  describe('submitSuggestionBatch', () => {
    const discussionIds = batchSuggestionsInfoMock.map(({ discussionId }) => discussionId);
    const batchSuggestionsInfo = batchSuggestionsInfoMock;

    let flashContainer;

    beforeEach(() => {
      jest.spyOn(Api, 'applySuggestionBatch');
      Api.applySuggestionBatch.mockReturnValue(Promise.resolve());
      const discussions = batchSuggestionsInfoMock.map(({ discussionId, noteId }) => {
        return { id: discussionId, notes: [{ id: noteId, suggestions: [] }] };
      });
      store.$patch({ discussions, batchSuggestionsInfo });
      flashContainer = {};
    });

    const submitSuggestionBatch = async () => {
      await store.submitSuggestionBatch({ flashContainer });
    };

    it('when service succeeds, commits, resolves discussions, resets batch and applying batch state', async () => {
      await submitSuggestionBatch();
      expect(store[types.SET_APPLYING_BATCH_STATE]).toHaveBeenNthCalledWith(1, true);
      expect(store[types.SET_RESOLVING_DISCUSSION]).toHaveBeenNthCalledWith(1, true);
      expect(store[types.CLEAR_SUGGESTION_BATCH]).toHaveBeenCalled();
      expect(store[types.SET_APPLYING_BATCH_STATE]).toHaveBeenNthCalledWith(2, false);
      expect(store[types.SET_RESOLVING_DISCUSSION]).toHaveBeenNthCalledWith(2, false);
      expect(store.resolveDiscussion).toHaveBeenNthCalledWith(1, {
        discussionId: discussionIds[0],
      });
      expect(store.resolveDiscussion).toHaveBeenNthCalledWith(2, {
        discussionId: discussionIds[1],
      });
      expect(createAlert).not.toHaveBeenCalled();
    });

    it('when service fails, flashes error message, resets applying batch state', async () => {
      const response = { response: { data: { message: TEST_ERROR_MESSAGE } } };

      Api.applySuggestionBatch.mockReturnValue(Promise.reject(response));

      await submitSuggestionBatch();
      expect(store[types.SET_APPLYING_BATCH_STATE]).toHaveBeenNthCalledWith(1, true);
      expect(store[types.SET_RESOLVING_DISCUSSION]).toHaveBeenNthCalledWith(1, true);
      expect(store[types.SET_APPLYING_BATCH_STATE]).toHaveBeenNthCalledWith(2, false);
      expect(store[types.SET_RESOLVING_DISCUSSION]).toHaveBeenNthCalledWith(2, false);
      expect(createAlert).toHaveBeenCalledWith({
        message: TEST_ERROR_MESSAGE,
        parent: flashContainer,
      });
    });

    it('when service fails, and no error message available, uses default message', async () => {
      const response = { response: 'foo' };

      Api.applySuggestionBatch.mockReturnValue(Promise.reject(response));

      await submitSuggestionBatch();
      expect(store[types.SET_APPLYING_BATCH_STATE]).toHaveBeenNthCalledWith(1, true);
      expect(store[types.SET_RESOLVING_DISCUSSION]).toHaveBeenNthCalledWith(1, true);
      expect(store[types.SET_APPLYING_BATCH_STATE]).toHaveBeenNthCalledWith(2, false);
      expect(store[types.SET_RESOLVING_DISCUSSION]).toHaveBeenNthCalledWith(2, false);
      expect(createAlert).toHaveBeenCalledWith({
        message: 'Something went wrong while applying the batch of suggestions. Please try again.',
        parent: flashContainer,
      });
    });

    it('when resolve discussions fails, fails gracefully, resets batch and applying batch state', async () => {
      store.resolveDiscussion.mockRejectedValue();

      await submitSuggestionBatch();

      expect(store[types.SET_APPLYING_BATCH_STATE]).toHaveBeenNthCalledWith(1, true);
      expect(store[types.SET_RESOLVING_DISCUSSION]).toHaveBeenNthCalledWith(1, true);
      expect(store[types.CLEAR_SUGGESTION_BATCH]).toHaveBeenCalled();
      expect(store[types.SET_APPLYING_BATCH_STATE]).toHaveBeenNthCalledWith(2, false);
      expect(store[types.SET_RESOLVING_DISCUSSION]).toHaveBeenNthCalledWith(2, false);
      expect(createAlert).not.toHaveBeenCalled();
    });
  });

  describe('addSuggestionInfoToBatch', () => {
    const suggestionInfo = batchSuggestionsInfoMock[0];

    it("adds a suggestion's info to the current batch", () => {
      return testAction(
        store.addSuggestionInfoToBatch,
        suggestionInfo,
        { batchSuggestionsInfo: [] },
        [{ type: store[types.ADD_SUGGESTION_TO_BATCH], payload: suggestionInfo }],
        [],
      );
    });
  });

  describe('removeSuggestionInfoFromBatch', () => {
    const suggestionInfo = batchSuggestionsInfoMock[0];

    it("removes a suggestion's info the current batch", () => {
      return testAction(
        store.removeSuggestionInfoFromBatch,
        suggestionInfo.suggestionId,
        { batchSuggestionsInfo: [suggestionInfo] },
        [{ type: store[types.REMOVE_SUGGESTION_FROM_BATCH], payload: suggestionInfo.suggestionId }],
        [],
      );
    });
  });

  describe('filterDiscussion', () => {
    const path = 'some-discussion-path';
    const filter = 0;

    beforeEach(() => {
      store.fetchDiscussions.mockResolvedValueOnce();
    });

    it('clears existing discussions', () => {
      store.filterDiscussion({ path, filter, persistFilter: false });

      expect(store[types.CLEAR_DISCUSSIONS]).toHaveBeenCalledTimes(1);
    });

    it('fetches discussions with filter and persistFilter false', () => {
      store.filterDiscussion({ path, filter, persistFilter: false });

      expect(store.setLoadingState).toHaveBeenCalledWith(true);
      expect(store.fetchDiscussions).toHaveBeenCalledWith({ path, filter, persistFilter: false });
    });

    it('fetches discussions with filter and persistFilter true', () => {
      store.filterDiscussion({ path, filter, persistFilter: true });

      expect(store.setLoadingState).toHaveBeenCalledWith(true);
      expect(store.fetchDiscussions).toHaveBeenCalledWith({ path, filter, persistFilter: true });
    });
  });

  describe('setDiscussionSortDirection', () => {
    it('calls the correct mutation with the correct args', () => {
      return testAction(
        store.setDiscussionSortDirection,
        { direction: notesConstants.DESC, persist: false },
        {},
        [
          {
            type: store[types.SET_DISCUSSIONS_SORT],
            payload: { direction: notesConstants.DESC, persist: false },
          },
        ],
        [],
      );
    });
  });

  describe('setSelectedCommentPosition', () => {
    it('calls the correct mutation with the correct args', () => {
      return testAction(
        store.setSelectedCommentPosition,
        {},
        {},
        [{ type: store[types.SET_SELECTED_COMMENT_POSITION], payload: {} }],
        [],
      );
    });
  });

  describe('softDeleteDescriptionVersion', () => {
    const endpoint = '/path/to/diff/1';
    const payload = {
      endpoint,
      startingVersion: undefined,
      versionId: 1,
    };

    describe('if response contains no errors', () => {
      it('dispatches requestDeleteDescriptionVersion', () => {
        axiosMock.onDelete(endpoint).replyOnce(HTTP_STATUS_OK);
        return testAction(
          store.softDeleteDescriptionVersion,
          payload,
          {},
          [],
          [
            {
              type: store.requestDeleteDescriptionVersion,
            },
            {
              type: store.receiveDeleteDescriptionVersion,
              payload: payload.versionId,
            },
          ],
        );
      });
    });

    describe('if response contains errors', () => {
      const errorMessage = 'Request failed with status code 503';
      it('dispatches receiveDeleteDescriptionVersionError and throws an error', async () => {
        axiosMock.onDelete(endpoint).replyOnce(HTTP_STATUS_SERVICE_UNAVAILABLE);
        await expect(
          testAction(
            store.softDeleteDescriptionVersion,
            payload,
            {},
            [],
            [
              {
                type: store.requestDeleteDescriptionVersion,
              },
              {
                type: store.receiveDeleteDescriptionVersionError,
                payload: new Error(errorMessage),
              },
            ],
          ),
        ).rejects.toEqual(new Error());

        expect(createAlert).toHaveBeenCalled();
      });
    });
  });

  describe('setConfidentiality', () => {
    it('calls the correct mutation with the correct args', () => {
      return testAction(store.setConfidentiality, true, { noteableData: { confidential: false } }, [
        { type: store[types.SET_ISSUE_CONFIDENTIAL], payload: true },
      ]);
    });
  });

  describe('updateAssignees', () => {
    it('update the assignees state', () => {
      return testAction(
        store.updateAssignees,
        [userDataMock.id],
        { discussions: [noteableDataMock] },
        [{ type: store[types.UPDATE_ASSIGNEES], payload: [userDataMock.id] }],
        [],
      );
    });
  });

  describe.each`
    issuableType
    ${'issue'}   | ${'merge_request'}
  `('updateLockedAttribute for issuableType=$issuableType', ({ issuableType }) => {
    // Payload for mutation query
    const targetType = issuableType;

    // Target state after mutation
    const locked = true;
    const actionArgs = { fullPath: 'full/path', locked };
    const input = { iid: '1', projectPath: 'full/path', locked: true };

    // Helper functions
    const targetMutation = () => {
      return targetType === 'issue' ? updateIssueLockMutation : updateMergeRequestLockMutation;
    };

    const mockResolvedValue = () => {
      return targetType === 'issue'
        ? { data: { issueSetLocked: { issue: { discussionLocked: locked } } } }
        : { data: { mergeRequestSetLocked: { mergeRequest: { discussionLocked: locked } } } };
    };

    beforeEach(() => {
      store.$patch({ noteableData: { discussion_locked: false, iid: '1', targetType } });
      jest.spyOn(utils.gqClient, 'mutate').mockResolvedValue(mockResolvedValue());
    });

    it('calls gqClient mutation one time', () => {
      store.updateLockedAttribute(actionArgs);

      expect(utils.gqClient.mutate).toHaveBeenCalledTimes(1);
    });

    it('calls gqClient mutation with the correct values', () => {
      store.updateLockedAttribute(actionArgs);

      expect(utils.gqClient.mutate).toHaveBeenCalledWith({
        mutation: targetMutation(),
        variables: { input },
      });
    });

    describe('on success of mutation', () => {
      it('calls commit with the correct values', async () => {
        await store.updateLockedAttribute(actionArgs);
        expect(store[types.SET_ISSUABLE_LOCK]).toHaveBeenCalledWith(locked);
      });
    });
  });

  describe('updateDiscussionPosition', () => {
    it('update the assignees state', () => {
      const updatedPosition = { discussionId: 1, position: { test: true } };
      return testAction(
        store.updateDiscussionPosition,
        updatedPosition,
        undefined,
        [{ type: store[types.UPDATE_DISCUSSION_POSITION], payload: updatedPosition }],
        [],
      );
    });
  });

  describe('promoteCommentToTimelineEvent', () => {
    const actionArgs = {
      noteId: '1',
      addError: 'addError: Create error',
      addGenericError: 'addGenericError',
    };

    describe('for successful request', () => {
      const timelineEventSuccessResponse = {
        data: {
          timelineEventPromoteFromNote: {
            timelineEvent: {
              id: 'gid://gitlab/IncidentManagement::TimelineEvent/19',
            },
            errors: [],
          },
        },
      };

      beforeEach(() => {
        jest.spyOn(utils.gqClient, 'mutate').mockResolvedValue(timelineEventSuccessResponse);
      });

      it('calls gqClient mutation with the correct values', () => {
        store.promoteCommentToTimelineEvent(actionArgs);

        expect(utils.gqClient.mutate).toHaveBeenCalledTimes(1);
        expect(utils.gqClient.mutate).toHaveBeenCalledWith({
          mutation: promoteTimelineEvent,
          variables: {
            input: {
              noteId: 'gid://gitlab/Note/1',
            },
          },
        });
      });

      it('returns success response', async () => {
        jest.spyOn(notesEventHub, '$emit').mockImplementation(() => {});

        await store.promoteCommentToTimelineEvent(actionArgs);
        expect(notesEventHub.$emit).toHaveBeenLastCalledWith('comment-promoted-to-timeline-event');
        expect(toast).toHaveBeenCalledWith('Comment added to the timeline.');
        expect(store[types.SET_PROMOTE_COMMENT_TO_TIMELINE_PROGRESS]).toHaveBeenCalledWith(false);
      });
    });

    describe('for failing request', () => {
      const errorResponse = {
        data: {
          timelineEventPromoteFromNote: {
            timelineEvent: null,
            errors: ['Create error'],
          },
        },
      };

      it.each`
        mockReject | message                     | captureError | error
        ${true}    | ${'addGenericError'}        | ${true}      | ${new Error()}
        ${false}   | ${'addError: Create error'} | ${false}     | ${null}
      `(
        'should show an error when submission fails',
        async ({ mockReject, message, captureError, error }) => {
          const expectedAlertArgs = {
            captureError,
            error,
            message,
          };
          if (mockReject) {
            jest.spyOn(utils.gqClient, 'mutate').mockRejectedValueOnce(new Error());
          } else {
            jest.spyOn(utils.gqClient, 'mutate').mockResolvedValue(errorResponse);
          }

          await store.promoteCommentToTimelineEvent(actionArgs);
          expect(createAlert).toHaveBeenCalledWith(expectedAlertArgs);
          expect(store[types.SET_PROMOTE_COMMENT_TO_TIMELINE_PROGRESS]).toHaveBeenCalledWith(false);
        },
      );
    });
  });

  describe('setFetchingState', () => {
    it('commits SET_NOTES_FETCHING_STATE', () => {
      return testAction(
        store.setFetchingState,
        true,
        null,
        [{ type: store[types.SET_NOTES_FETCHING_STATE], payload: true }],
        [],
      );
    });
  });

  describe('fetchDiscussions', () => {
    const discussion = { notes: [] };

    it('updates the discussions and dispatches `updateResolvableDiscussionsCounts`', () => {
      axiosMock.onAny().reply(HTTP_STATUS_OK, [discussion]);
      return testAction(
        store.fetchDiscussions,
        {},
        undefined,
        [
          { type: store[types.ADD_OR_UPDATE_DISCUSSIONS], payload: [discussion] },
          { type: store[types.SET_FETCHING_DISCUSSIONS], payload: false },
        ],
        [{ type: store.updateResolvableDiscussionsCounts }],
      );
    });

    it('dispatches `fetchDiscussionsBatch` action with notes_filter 0 for merge request', async () => {
      const mock = store.fetchDiscussionsBatch.mockReturnValueOnce(Promise.resolve());
      await testAction(
        store.fetchDiscussions,
        { path: 'test-path', filter: 'test-filter', persistFilter: 'test-persist-filter' },
        { noteableData: { merge_params: {} } },
        [],
        [
          {
            type: mock,
            payload: {
              config: {
                params: { notes_filter: 0, persist_filter: false },
              },
              path: 'test-path',
              perPage: 20,
            },
          },
        ],
      );
    });

    it('dispatches `fetchDiscussionsBatch` action if noteable is an Issue', () => {
      const mock = store.fetchDiscussionsBatch.mockReturnValueOnce(Promise.resolve());
      return testAction(
        store.fetchDiscussions,
        { path: 'test-path', filter: 'test-filter', persistFilter: 'test-persist-filter' },
        undefined,
        [],
        [
          {
            type: mock,
            payload: {
              config: {
                params: { notes_filter: 'test-filter', persist_filter: 'test-persist-filter' },
              },
              path: 'test-path',
              perPage: 20,
            },
          },
        ],
      );
    });

    it('dispatches `fetchDiscussionsBatch` action if noteable is a MergeRequest', () => {
      const mock = store.fetchDiscussionsBatch.mockReturnValueOnce(Promise.resolve());
      return testAction(
        store.fetchDiscussions,
        { path: 'test-path', filter: 'test-filter', persistFilter: 'test-persist-filter' },
        { noteableData: { merge_params: {} } },
        [],
        [
          {
            type: mock,
            payload: {
              config: {
                params: { notes_filter: 0, persist_filter: false },
              },
              path: 'test-path',
              perPage: 20,
            },
          },
        ],
      );
    });
  });

  describe('fetchDiscussionsBatch', () => {
    const discussion = { notes: [] };

    const config = {
      params: { notes_filter: 'test-filter', persist_filter: 'test-persist-filter' },
    };

    const actionPayload = { config, path: 'test-path', perPage: 20 };

    it('updates the discussions and dispatches `updateResolvableDiscussionsCounts if there are no headers', () => {
      axiosMock.onAny().reply(HTTP_STATUS_OK, [discussion], {});
      return testAction(
        store.fetchDiscussionsBatch,
        actionPayload,
        null,
        [
          { type: store[types.ADD_OR_UPDATE_DISCUSSIONS], payload: [discussion] },
          { type: store[types.SET_DONE_FETCHING_BATCH_DISCUSSIONS], payload: true },
          { type: store[types.SET_FETCHING_DISCUSSIONS], payload: false },
        ],
        [{ type: store.updateResolvableDiscussionsCounts }],
      );
    });

    it('dispatches itself if there is `x-next-page-cursor` header', () => {
      axiosMock.onAny().replyOnce(HTTP_STATUS_OK, [discussion], { 'x-next-page-cursor': 1 });
      axiosMock.onAny().replyOnce(HTTP_STATUS_OK, []);
      return testAction(
        store.fetchDiscussionsBatch,
        actionPayload,
        null,
        [{ type: store[types.ADD_OR_UPDATE_DISCUSSIONS], payload: [discussion] }],
        [
          {
            type: store.fetchDiscussionsBatch,
            payload: actionPayload,
          },
          {
            type: store.fetchDiscussionsBatch,
            payload: { ...actionPayload, perPage: 30, cursor: 1 },
          },
        ],
      );
    });
  });

  describe('toggleAllDiscussions', () => {
    it('commits SET_EXPAND_ALL_DISCUSSIONS', () => {
      return testAction(
        store.toggleAllDiscussions,
        undefined,
        { discussions: [{ expanded: false }] },
        [{ type: store[types.SET_EXPAND_ALL_DISCUSSIONS], payload: true }],
        [],
      );
    });
  });
});
