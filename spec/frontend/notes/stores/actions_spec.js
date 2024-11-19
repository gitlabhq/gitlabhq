import AxiosMockAdapter from 'axios-mock-adapter';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';
import actionCable from '~/actioncable_consumer';
import Api from '~/api';
import { createAlert } from '~/alert';
import toast from '~/vue_shared/plugins/global_toast';
import { EVENT_ISSUABLE_VUE_APP_CHANGE } from '~/issuable/constants';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK, HTTP_STATUS_SERVICE_UNAVAILABLE } from '~/lib/utils/http_status';
import * as notesConstants from '~/notes/constants';
import createStore from '~/notes/stores';
import * as actions from '~/notes/stores/actions';
import * as mutationTypes from '~/notes/stores/mutation_types';
import mutations from '~/notes/stores/mutations';
import * as utils from '~/notes/stores/utils';
import updateIssueLockMutation from '~/sidebar/queries/update_issue_lock.mutation.graphql';
import updateMergeRequestLockMutation from '~/sidebar/queries/update_merge_request_lock.mutation.graphql';
import promoteTimelineEvent from '~/notes/graphql/promote_timeline_event.mutation.graphql';
import mrWidgetEventHub from '~/vue_merge_request_widget/event_hub';
import notesEventHub from '~/notes/event_hub';
import { resetStore } from '../helpers';
import {
  discussionMock,
  notesDataMock,
  userDataMock,
  noteableDataMock,
  individualNote,
  batchSuggestionsInfoMock,
} from '../mock_data';

const TEST_ERROR_MESSAGE = 'Test error message';
const mockAlertDismiss = jest.fn();
jest.mock('~/alert', () => ({
  createAlert: jest.fn().mockImplementation(() => ({
    dismiss: mockAlertDismiss,
  })),
}));

jest.mock('~/vue_shared/plugins/global_toast');

describe('Actions Notes Store', () => {
  let commit;
  let dispatch;
  let state;
  let store;
  let axiosMock;

  beforeEach(() => {
    store = createStore();
    commit = jest.fn();
    dispatch = jest.fn();
    state = {};
    axiosMock = new AxiosMockAdapter(axios);

    // This is necessary as we query Close issue button at the top of issue page when clicking bottom button
    setHTMLFixture(
      '<div class="detail-page-header-actions"><button class="btn-close btn-grouped"></button></div>',
    );
  });

  afterEach(() => {
    resetStore(store);
    axiosMock.restore();
    resetHTMLFixture();

    window.gon = {};
  });

  describe('setNotesData', () => {
    it('should set received notes data', () => {
      return testAction(
        actions.setNotesData,
        notesDataMock,
        { notesData: {} },
        [{ type: 'SET_NOTES_DATA', payload: notesDataMock }],
        [],
      );
    });
  });

  describe('setNoteableData', () => {
    it('should set received issue data', () => {
      return testAction(
        actions.setNoteableData,
        noteableDataMock,
        { noteableData: {} },
        [{ type: 'SET_NOTEABLE_DATA', payload: noteableDataMock }],
        [],
      );
    });
  });

  describe('setUserData', () => {
    it('should set received user data', () => {
      return testAction(
        actions.setUserData,
        userDataMock,
        { userData: {} },
        [{ type: 'SET_USER_DATA', payload: userDataMock }],
        [],
      );
    });
  });

  describe('setLastFetchedAt', () => {
    it('should set received timestamp', () => {
      return testAction(
        actions.setLastFetchedAt,
        'timestamp',
        { lastFetchedAt: {} },
        [{ type: 'SET_LAST_FETCHED_AT', payload: 'timestamp' }],
        [],
      );
    });
  });

  describe('setInitialNotes', () => {
    it('should set initial notes', () => {
      return testAction(
        actions.setInitialNotes,
        [individualNote],
        { notes: [] },
        [{ type: 'ADD_OR_UPDATE_DISCUSSIONS', payload: [individualNote] }],
        [],
      );
    });
  });

  describe('setTargetNoteHash', () => {
    it('should set target note hash', () => {
      return testAction(
        actions.setTargetNoteHash,
        'hash',
        { notes: [] },
        [{ type: 'SET_TARGET_NOTE_HASH', payload: 'hash' }],
        [],
      );
    });
  });

  describe('toggleDiscussion', () => {
    it('should toggle discussion', () => {
      return testAction(
        actions.toggleDiscussion,
        { discussionId: discussionMock.id },
        { notes: [discussionMock] },
        [{ type: 'TOGGLE_DISCUSSION', payload: { discussionId: discussionMock.id } }],
        [],
      );
    });
  });

  describe('expandDiscussion', () => {
    it('should expand discussion', () => {
      return testAction(
        actions.expandDiscussion,
        { discussionId: discussionMock.id },
        { notes: [discussionMock] },
        [{ type: 'EXPAND_DISCUSSION', payload: { discussionId: discussionMock.id } }],
        [{ type: 'diffs/renderFileForDiscussionId', payload: discussionMock.id }],
      );
    });
  });

  describe('collapseDiscussion', () => {
    it('should commit collapse discussion', () => {
      return testAction(
        actions.collapseDiscussion,
        { discussionId: discussionMock.id },
        { notes: [discussionMock] },
        [{ type: 'COLLAPSE_DISCUSSION', payload: { discussionId: discussionMock.id } }],
        [],
      );
    });
  });

  describe('async methods', () => {
    beforeEach(() => {
      axiosMock.onAny().reply(HTTP_STATUS_OK, {});
    });

    describe('closeMergeRequest', () => {
      it('sets state as closed', async () => {
        await store.dispatch('closeIssuable', { notesData: { closeIssuePath: '' } });
        expect(store.state.noteableData.state).toEqual('closed');
        expect(store.state.isToggleStateButtonLoading).toEqual(false);
      });
    });

    describe('reopenMergeRequest', () => {
      it('sets state as reopened', async () => {
        await store.dispatch('reopenIssuable', { notesData: { reopenIssuePath: '' } });
        expect(store.state.noteableData.state).toEqual('reopened');
        expect(store.state.isToggleStateButtonLoading).toEqual(false);
      });
    });
  });

  describe('emitStateChangedEvent', () => {
    it('emits an event on the document', () => {
      document.addEventListener(EVENT_ISSUABLE_VUE_APP_CHANGE, (event) => {
        expect(event.detail.data).toEqual({ id: '1', state: 'closed' });
        expect(event.detail.isClosed).toEqual(false);
      });

      store.dispatch('emitStateChangedEvent', { id: '1', state: 'closed' });
    });
  });

  describe('toggleStateButtonLoading', () => {
    it('should set loading as true', () => {
      return testAction(
        actions.toggleStateButtonLoading,
        true,
        {},
        [{ type: 'TOGGLE_STATE_BUTTON_LOADING', payload: true }],
        [],
      );
    });

    it('should set loading as false', () => {
      return testAction(
        actions.toggleStateButtonLoading,
        false,
        {},
        [{ type: 'TOGGLE_STATE_BUTTON_LOADING', payload: false }],
        [],
      );
    });
  });

  describe('toggleIssueLocalState', () => {
    it('sets issue state as closed', () => {
      return testAction(actions.toggleIssueLocalState, 'closed', {}, [{ type: 'CLOSE_ISSUE' }], []);
    });

    it('sets issue state as reopened', () => {
      return testAction(
        actions.toggleIssueLocalState,
        'reopened',
        {},
        [{ type: 'REOPEN_ISSUE' }],
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
      project_id: store.state.notesData.projectId,
      group_id: store.state.notesData.groupId,
      noteable_type: store.state.notesData.noteableType,
      noteable_id: store.state.notesData.noteableId,
    });

    const notifyNotesChannel = () => {
      actionCable.subscriptions.notify(JSON.stringify(notesChannelParams()), 'received', {
        event: 'updated',
      });
    };

    it('creates the Action Cable subscription', () => {
      jest.spyOn(actionCable.subscriptions, 'create');

      store.dispatch('setNotesData', notesDataMock);
      store.dispatch('initPolling');

      expect(actionCable.subscriptions.create).toHaveBeenCalledTimes(1);
      expect(actionCable.subscriptions.create).toHaveBeenCalledWith(
        notesChannelParams(),
        expect.any(Object),
      );
    });

    it('prevents `fetchUpdatedNotes` being called multiple times within time limit when action cable receives contineously new events', () => {
      const getters = { getNotesDataByProp: () => 123456789 };

      store.dispatch('setNotesData', notesDataMock);
      actions.initPolling({ commit, state: store.state, getters, dispatch });

      dispatch.mockClear();

      notifyNotesChannel();
      notifyNotesChannel();
      notifyNotesChannel();

      jest.runOnlyPendingTimers();

      expect(dispatch).toHaveBeenCalledTimes(1);
      expect(dispatch).toHaveBeenCalledWith('fetchUpdatedNotes');
    });
  });

  describe('fetchUpdatedNotes', () => {
    const response = { notes: [], last_fetched_at: '123456' };
    const successMock = () =>
      axiosMock.onGet(notesDataMock.notesPath).reply(HTTP_STATUS_OK, response);

    beforeEach(() => {
      return store.dispatch('setNotesData', notesDataMock);
    });

    it('calls the endpoint and stores last fetched state', async () => {
      successMock();

      await store.dispatch('fetchUpdatedNotes');

      expect(store.state.lastFetchedAt).toBe('123456');
    });
  });

  describe('setNotesFetchedState', () => {
    it('should set notes fetched state', () => {
      return testAction(
        actions.setNotesFetchedState,
        true,
        {},
        [{ type: 'SET_NOTES_FETCHED_STATE', payload: true }],
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
      const note = { path: endpoint, id: 1 };

      return testAction(
        actions.removeNote,
        note,
        store.state,
        [
          {
            type: 'DELETE_NOTE',
            payload: note,
          },
        ],
        [
          {
            type: 'updateMergeRequestWidget',
          },
          {
            type: 'updateResolvableDiscussionsCounts',
          },
        ],
      );
    });

    it('dispatches removeDiscussionsFromDiff on merge request page', () => {
      const note = { path: endpoint, id: 1 };

      document.body.dataset.page = 'projects:merge_requests:show';

      return testAction(
        actions.removeNote,
        note,
        store.state,
        [
          {
            type: 'DELETE_NOTE',
            payload: note,
          },
        ],
        [
          {
            type: 'updateMergeRequestWidget',
          },
          {
            type: 'updateResolvableDiscussionsCounts',
          },
          {
            type: 'diffs/removeDiscussionsFromDiff',
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
      const note = { path: endpoint, id: 1 };

      return testAction(
        actions.deleteNote,
        note,
        {},
        [],
        [
          {
            type: 'removeNote',
            payload: {
              id: 1,
              path: 'http://test.host/note',
            },
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
          actions.createNewNote,
          { endpoint: `${TEST_HOST}`, data: {} },
          store.state,
          [
            {
              type: 'ADD_NEW_NOTE',
              payload: res,
            },
          ],
          [
            {
              type: 'updateMergeRequestWidget',
            },
            {
              type: 'startTaskList',
            },
            {
              type: 'updateResolvableDiscussionsCounts',
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
          actions.createNewNote,
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
    };

    beforeEach(() => {
      axiosMock.onAny().reply(HTTP_STATUS_OK, res);
    });

    describe('as note', () => {
      it('commits UPDATE_NOTE and dispatches updateMergeRequestWidget', () => {
        return testAction(
          actions.toggleResolveNote,
          { endpoint: `${TEST_HOST}`, isResolved: true, discussion: false },
          store.state,
          [
            {
              type: 'UPDATE_NOTE',
              payload: res,
            },
          ],
          [
            {
              type: 'updateResolvableDiscussionsCounts',
            },
            {
              type: 'updateMergeRequestWidget',
            },
          ],
        );
      });
    });

    describe('as discussion', () => {
      it('commits UPDATE_DISCUSSION and dispatches updateMergeRequestWidget', () => {
        return testAction(
          actions.toggleResolveNote,
          { endpoint: `${TEST_HOST}`, isResolved: true, discussion: true },
          store.state,
          [
            {
              type: 'UPDATE_DISCUSSION',
              payload: res,
            },
          ],
          [
            {
              type: 'updateResolvableDiscussionsCounts',
            },
            {
              type: 'updateMergeRequestWidget',
            },
          ],
        );
      });
    });
  });

  describe('updateMergeRequestWidget', () => {
    it('calls mrWidget checkStatus', () => {
      jest.spyOn(mrWidgetEventHub, '$emit').mockImplementation(() => {});

      actions.updateMergeRequestWidget();

      expect(mrWidgetEventHub.$emit).toHaveBeenCalledWith('mr.discussion.updated');
    });
  });

  describe('setCommentsDisabled', () => {
    it('should set comments disabled state', () => {
      return testAction(
        actions.setCommentsDisabled,
        true,
        null,
        [{ type: 'DISABLE_COMMENTS', payload: true }],
        [],
      );
    });
  });

  describe('updateResolvableDiscussionsCounts', () => {
    it('commits UPDATE_RESOLVABLE_DISCUSSIONS_COUNTS', () => {
      return testAction(
        actions.updateResolvableDiscussionsCounts,
        null,
        {},
        [{ type: 'UPDATE_RESOLVABLE_DISCUSSIONS_COUNTS' }],
        [],
      );
    });
  });

  describe('convertToDiscussion', () => {
    it('commits CONVERT_TO_DISCUSSION with noteId', () => {
      const noteId = 'dummy-note-id';
      return testAction(
        actions.convertToDiscussion,
        noteId,
        {},
        [{ type: 'CONVERT_TO_DISCUSSION', payload: noteId }],
        [],
      );
    });
  });

  describe('updateOrCreateNotes', () => {
    it('Prevents `fetchDiscussions` being called multiple times within time limit', () => {
      const note = { id: 1234, type: notesConstants.DIFF_NOTE };
      const getters = { notesById: {} };
      state = { discussions: [note], notesData: { discussionsPath: '' } };
      commit.mockImplementation((type, value) => {
        if (type === mutationTypes.SET_FETCHING_DISCUSSIONS) {
          mutations[type](state, value);
        }
      });

      actions.updateOrCreateNotes({ commit, state, getters, dispatch }, [note]);
      actions.updateOrCreateNotes({ commit, state, getters, dispatch }, [note]);

      jest.runOnlyPendingTimers();

      actions.updateOrCreateNotes({ commit, state, getters, dispatch }, [note]);

      expect(dispatch).toHaveBeenCalledTimes(2);
    });

    it('Updates existing note', () => {
      const note = { id: 1234 };
      const getters = { notesById: { 1234: note } };

      actions.updateOrCreateNotes({ commit, state, getters, dispatch }, [note]);

      expect(commit.mock.calls).toEqual([[mutationTypes.UPDATE_NOTE, note]]);
    });

    it('Creates a new note if none exisits', () => {
      const note = { id: 1234 };
      const getters = { notesById: {} };
      actions.updateOrCreateNotes({ commit, state, getters, dispatch }, [note]);

      expect(commit.mock.calls).toEqual([[mutationTypes.ADD_NEW_NOTE, note]]);
    });

    describe('Discussion notes', () => {
      let note;
      let getters;

      beforeEach(() => {
        note = { id: 1234 };
        getters = { notesById: {} };
      });

      it('Adds a reply to an existing discussion', () => {
        state = { discussions: [note] };
        const discussionNote = {
          ...note,
          type: notesConstants.DISCUSSION_NOTE,
          discussion_id: 1234,
        };

        actions.updateOrCreateNotes({ commit, state, getters, dispatch }, [discussionNote]);

        expect(commit.mock.calls).toEqual([
          [mutationTypes.ADD_NEW_REPLY_TO_DISCUSSION, discussionNote],
        ]);
      });

      it('fetches discussions for diff notes', () => {
        state = { discussions: [], notesData: { discussionsPath: 'Hello world' } };
        const diffNote = { ...note, type: notesConstants.DIFF_NOTE, discussion_id: 1234 };

        actions.updateOrCreateNotes({ commit, state, getters, dispatch }, [diffNote]);

        expect(dispatch.mock.calls).toEqual([
          ['fetchDiscussions', { path: state.notesData.discussionsPath }],
        ]);
      });

      it('Adds a new note', () => {
        state = { discussions: [] };
        const discussionNote = {
          ...note,
          type: notesConstants.DISCUSSION_NOTE,
          discussion_id: 1234,
        };

        actions.updateOrCreateNotes({ commit, state, getters, dispatch }, [discussionNote]);

        expect(commit.mock.calls).toEqual([[mutationTypes.ADD_NEW_NOTE, discussionNote]]);
      });
    });
  });

  describe('replyToDiscussion', () => {
    const payload = { endpoint: TEST_HOST, data: {} };

    it('updates discussion if response contains disussion', () => {
      const discussion = { notes: [] };
      axiosMock.onAny().reply(HTTP_STATUS_OK, { discussion });

      return testAction(
        actions.replyToDiscussion,
        payload,
        {
          notesById: {},
        },
        [{ type: mutationTypes.UPDATE_DISCUSSION, payload: discussion }],
        [
          { type: 'updateMergeRequestWidget' },
          { type: 'startTaskList' },
          { type: 'updateResolvableDiscussionsCounts' },
        ],
      );
    });

    it('adds a reply to a discussion', () => {
      const res = {};
      axiosMock.onAny().reply(HTTP_STATUS_OK, res);

      return testAction(
        actions.replyToDiscussion,
        payload,
        {
          notesById: {},
        },
        [{ type: mutationTypes.ADD_NEW_REPLY_TO_DISCUSSION, payload: res }],
        [],
      );
    });
  });

  describe('removeConvertedDiscussion', () => {
    it('commits CONVERT_TO_DISCUSSION with noteId', () => {
      const noteId = 'dummy-id';
      return testAction(
        actions.removeConvertedDiscussion,
        noteId,
        {},
        [{ type: 'REMOVE_CONVERTED_DISCUSSION', payload: noteId }],
        [],
      );
    });
  });

  describe('resolveDiscussion', () => {
    let getters;
    let discussionId;

    beforeEach(() => {
      discussionId = discussionMock.id;
      state.discussions = [discussionMock];
      getters = {
        isDiscussionResolved: () => false,
      };
    });

    it('when unresolved, dispatches action', () => {
      return testAction(
        actions.resolveDiscussion,
        { discussionId },
        { ...state, ...getters },
        [],
        [
          {
            type: 'toggleResolveNote',
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

      return testAction(
        actions.resolveDiscussion,
        { discussionId },
        { ...state, ...getters },
        [],
        [],
      );
    });
  });

  describe('saveNote', () => {
    const flashContainer = {};
    const payload = { endpoint: TEST_HOST, data: { 'note[note]': 'some text' }, flashContainer };

    describe('if response contains errors', () => {
      const res = { errors: { something: ['went wrong'] } };
      const error = { message: 'Unprocessable entity', response: { data: res } };

      it('throws an error', async () => {
        await expect(
          actions.saveNote(
            {
              commit() {},
              dispatch: () => Promise.reject(error),
            },
            payload,
          ),
        ).rejects.toEqual(error);
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('if response contains no errors', () => {
      const res = { valid: true };

      it('returns the response', async () => {
        const data = await actions.saveNote(
          {
            commit() {},
            dispatch: () => Promise.resolve(res),
          },
          payload,
        );
        expect(data).toBe(res);
        expect(createAlert).not.toHaveBeenCalled();
      });

      it('dispatches clearDrafts is command names contains submit_review', async () => {
        const response = {
          quick_actions_status: { command_names: ['submit_review'] },
          valid: true,
        };
        dispatch = jest.fn().mockResolvedValue(response);
        await actions.saveNote(
          {
            commit() {},
            dispatch,
          },
          payload,
        );

        expect(dispatch).toHaveBeenCalledWith('batchComments/clearDrafts');
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
      dispatch.mockReturnValue(Promise.resolve());
      flashContainer = {};
    });

    const testSubmitSuggestion = async (expectFn) => {
      await actions.submitSuggestion(
        { commit, dispatch },
        { discussionId, noteId, suggestionId, flashContainer },
      );

      expectFn();
    };

    it('when service success, commits and resolves discussion', () => {
      testSubmitSuggestion(() => {
        expect(commit.mock.calls).toEqual([
          [mutationTypes.SET_RESOLVING_DISCUSSION, true],
          [mutationTypes.SET_RESOLVING_DISCUSSION, false],
        ]);

        expect(dispatch.mock.calls).toEqual([['resolveDiscussion', { discussionId }]]);
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    it('when service fails, creates an alert with error message', () => {
      const response = { response: { data: { message: TEST_ERROR_MESSAGE } } };

      Api.applySuggestion.mockReturnValue(Promise.reject(response));

      return testSubmitSuggestion(() => {
        expect(commit.mock.calls).toEqual([
          [mutationTypes.SET_RESOLVING_DISCUSSION, true],
          [mutationTypes.SET_RESOLVING_DISCUSSION, false],
        ]);
        expect(createAlert).toHaveBeenCalledWith({
          message: TEST_ERROR_MESSAGE,
          parent: flashContainer,
        });
      });
    });

    it('when service fails, and no error message available, uses default message', () => {
      const response = { response: 'foo' };

      Api.applySuggestion.mockReturnValue(Promise.reject(response));

      return testSubmitSuggestion(() => {
        expect(commit.mock.calls).toEqual([
          [mutationTypes.SET_RESOLVING_DISCUSSION, true],
          [mutationTypes.SET_RESOLVING_DISCUSSION, false],
        ]);
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Something went wrong while applying the suggestion. Please try again.',
          parent: flashContainer,
        });
      });
    });

    it('when resolve discussion fails, fail gracefully', () => {
      dispatch.mockReturnValue(Promise.reject());

      return testSubmitSuggestion(() => {
        expect(createAlert).not.toHaveBeenCalled();
      });
    });
  });

  describe('submitSuggestionBatch', () => {
    const discussionIds = batchSuggestionsInfoMock.map(({ discussionId }) => discussionId);
    const batchSuggestionsInfo = batchSuggestionsInfoMock;

    let flashContainer;

    beforeEach(() => {
      jest.spyOn(Api, 'applySuggestionBatch');
      dispatch.mockReturnValue(Promise.resolve());
      Api.applySuggestionBatch.mockReturnValue(Promise.resolve());
      state = { batchSuggestionsInfo };
      flashContainer = {};
    });

    const testSubmitSuggestionBatch = async (expectFn) => {
      await actions.submitSuggestionBatch({ commit, dispatch, state }, { flashContainer });

      expectFn();
    };

    it('when service succeeds, commits, resolves discussions, resets batch and applying batch state', () => {
      testSubmitSuggestionBatch(() => {
        expect(commit.mock.calls).toEqual([
          [mutationTypes.SET_APPLYING_BATCH_STATE, true],
          [mutationTypes.SET_RESOLVING_DISCUSSION, true],
          [mutationTypes.CLEAR_SUGGESTION_BATCH],
          [mutationTypes.SET_APPLYING_BATCH_STATE, false],
          [mutationTypes.SET_RESOLVING_DISCUSSION, false],
        ]);

        expect(dispatch.mock.calls).toEqual([
          ['resolveDiscussion', { discussionId: discussionIds[0] }],
          ['resolveDiscussion', { discussionId: discussionIds[1] }],
        ]);

        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    it('when service fails, flashes error message, resets applying batch state', () => {
      const response = { response: { data: { message: TEST_ERROR_MESSAGE } } };

      Api.applySuggestionBatch.mockReturnValue(Promise.reject(response));

      testSubmitSuggestionBatch(() => {
        expect(commit.mock.calls).toEqual([
          [mutationTypes.SET_APPLYING_BATCH_STATE, true],
          [mutationTypes.SET_RESOLVING_DISCUSSION, true],
          [mutationTypes.SET_APPLYING_BATCH_STATE, false],
          [mutationTypes.SET_RESOLVING_DISCUSSION, false],
        ]);

        expect(createAlert).toHaveBeenCalledWith({
          message: TEST_ERROR_MESSAGE,
          parent: flashContainer,
        });
      });
    });

    it('when service fails, and no error message available, uses default message', () => {
      const response = { response: 'foo' };

      Api.applySuggestionBatch.mockReturnValue(Promise.reject(response));

      testSubmitSuggestionBatch(() => {
        expect(commit.mock.calls).toEqual([
          [mutationTypes.SET_APPLYING_BATCH_STATE, true],
          [mutationTypes.SET_RESOLVING_DISCUSSION, true],
          [mutationTypes.SET_APPLYING_BATCH_STATE, false],
          [mutationTypes.SET_RESOLVING_DISCUSSION, false],
        ]);

        expect(createAlert).toHaveBeenCalledWith({
          message:
            'Something went wrong while applying the batch of suggestions. Please try again.',
          parent: flashContainer,
        });
      });
    });

    it('when resolve discussions fails, fails gracefully, resets batch and applying batch state', () => {
      dispatch.mockReturnValue(Promise.reject());

      testSubmitSuggestionBatch(() => {
        expect(commit.mock.calls).toEqual([
          [mutationTypes.SET_APPLYING_BATCH_STATE, true],
          [mutationTypes.SET_RESOLVING_DISCUSSION, true],
          [mutationTypes.CLEAR_SUGGESTION_BATCH],
          [mutationTypes.SET_APPLYING_BATCH_STATE, false],
          [mutationTypes.SET_RESOLVING_DISCUSSION, false],
        ]);

        expect(createAlert).not.toHaveBeenCalled();
      });
    });
  });

  describe('addSuggestionInfoToBatch', () => {
    const suggestionInfo = batchSuggestionsInfoMock[0];

    it("adds a suggestion's info to the current batch", () => {
      return testAction(
        actions.addSuggestionInfoToBatch,
        suggestionInfo,
        { batchSuggestionsInfo: [] },
        [{ type: 'ADD_SUGGESTION_TO_BATCH', payload: suggestionInfo }],
        [],
      );
    });
  });

  describe('removeSuggestionInfoFromBatch', () => {
    const suggestionInfo = batchSuggestionsInfoMock[0];

    it("removes a suggestion's info the current batch", () => {
      return testAction(
        actions.removeSuggestionInfoFromBatch,
        suggestionInfo.suggestionId,
        { batchSuggestionsInfo: [suggestionInfo] },
        [{ type: 'REMOVE_SUGGESTION_FROM_BATCH', payload: suggestionInfo.suggestionId }],
        [],
      );
    });
  });

  describe('filterDiscussion', () => {
    const path = 'some-discussion-path';
    const filter = 0;

    beforeEach(() => {
      dispatch.mockReturnValue(new Promise(() => {}));
    });

    it('clears existing discussions', () => {
      actions.filterDiscussion({ commit, dispatch }, { path, filter, persistFilter: false });

      expect(commit.mock.calls).toEqual([[mutationTypes.CLEAR_DISCUSSIONS]]);
    });

    it('fetches discussions with filter and persistFilter false', () => {
      actions.filterDiscussion({ commit, dispatch }, { path, filter, persistFilter: false });

      expect(dispatch.mock.calls).toEqual([
        ['setLoadingState', true],
        ['fetchDiscussions', { path, filter, persistFilter: false }],
      ]);
    });

    it('fetches discussions with filter and persistFilter true', () => {
      actions.filterDiscussion({ commit, dispatch }, { path, filter, persistFilter: true });

      expect(dispatch.mock.calls).toEqual([
        ['setLoadingState', true],
        ['fetchDiscussions', { path, filter, persistFilter: true }],
      ]);
    });
  });

  describe('setDiscussionSortDirection', () => {
    it('calls the correct mutation with the correct args', () => {
      return testAction(
        actions.setDiscussionSortDirection,
        { direction: notesConstants.DESC, persist: false },
        {},
        [
          {
            type: mutationTypes.SET_DISCUSSIONS_SORT,
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
        actions.setSelectedCommentPosition,
        {},
        {},
        [{ type: mutationTypes.SET_SELECTED_COMMENT_POSITION, payload: {} }],
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
          actions.softDeleteDescriptionVersion,
          payload,
          {},
          [],
          [
            {
              type: 'requestDeleteDescriptionVersion',
            },
            {
              type: 'receiveDeleteDescriptionVersion',
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
            actions.softDeleteDescriptionVersion,
            payload,
            {},
            [],
            [
              {
                type: 'requestDeleteDescriptionVersion',
              },
              {
                type: 'receiveDeleteDescriptionVersionError',
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
      return testAction(
        actions.setConfidentiality,
        true,
        { noteableData: { confidential: false } },
        [{ type: mutationTypes.SET_ISSUE_CONFIDENTIAL, payload: true }],
      );
    });
  });

  describe('updateAssignees', () => {
    it('update the assignees state', () => {
      return testAction(
        actions.updateAssignees,
        [userDataMock.id],
        { state: noteableDataMock },
        [{ type: mutationTypes.UPDATE_ASSIGNEES, payload: [userDataMock.id] }],
        [],
      );
    });
  });

  describe.each`
    issuableType
    ${'issue'}   | ${'merge_request'}
  `('updateLockedAttribute for issuableType=$issuableType', ({ issuableType }) => {
    // Payload for mutation query
    state = { noteableData: { discussion_locked: false } };
    const targetType = issuableType;
    const getters = { getNoteableData: { iid: '1', targetType } };

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
      jest.spyOn(utils.gqClient, 'mutate').mockResolvedValue(mockResolvedValue());
    });

    it('calls gqClient mutation one time', () => {
      actions.updateLockedAttribute({ commit: () => {}, state, getters }, actionArgs);

      expect(utils.gqClient.mutate).toHaveBeenCalledTimes(1);
    });

    it('calls gqClient mutation with the correct values', () => {
      actions.updateLockedAttribute({ commit: () => {}, state, getters }, actionArgs);

      expect(utils.gqClient.mutate).toHaveBeenCalledWith({
        mutation: targetMutation(),
        variables: { input },
      });
    });

    describe('on success of mutation', () => {
      it('calls commit with the correct values', () => {
        const commitSpy = jest.fn();

        return actions
          .updateLockedAttribute({ commit: commitSpy, state, getters }, actionArgs)
          .then(() => {
            expect(commitSpy).toHaveBeenCalledWith(mutationTypes.SET_ISSUABLE_LOCK, locked);
          });
      });
    });
  });

  describe('updateDiscussionPosition', () => {
    it('update the assignees state', () => {
      const updatedPosition = { discussionId: 1, position: { test: true } };
      return testAction(
        actions.updateDiscussionPosition,
        updatedPosition,
        { state: { discussions: [] } },
        [{ type: mutationTypes.UPDATE_DISCUSSION_POSITION, payload: updatedPosition }],
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
    const commitSpy = jest.fn();

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
        actions.promoteCommentToTimelineEvent({ commit: () => {} }, actionArgs);

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

      it('returns success response', () => {
        jest.spyOn(notesEventHub, '$emit').mockImplementation(() => {});

        return actions.promoteCommentToTimelineEvent({ commit: commitSpy }, actionArgs).then(() => {
          expect(notesEventHub.$emit).toHaveBeenLastCalledWith(
            'comment-promoted-to-timeline-event',
          );
          expect(toast).toHaveBeenCalledWith('Comment added to the timeline.');
          expect(commitSpy).toHaveBeenCalledWith(
            mutationTypes.SET_PROMOTE_COMMENT_TO_TIMELINE_PROGRESS,
            false,
          );
        });
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
        ({ mockReject, message, captureError, error }) => {
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

          return actions
            .promoteCommentToTimelineEvent({ commit: commitSpy }, actionArgs)
            .then(() => {
              expect(createAlert).toHaveBeenCalledWith(expectedAlertArgs);
              expect(commitSpy).toHaveBeenCalledWith(
                mutationTypes.SET_PROMOTE_COMMENT_TO_TIMELINE_PROGRESS,
                false,
              );
            });
        },
      );
    });
  });

  describe('setFetchingState', () => {
    it('commits SET_NOTES_FETCHING_STATE', () => {
      return testAction(
        actions.setFetchingState,
        true,
        null,
        [{ type: mutationTypes.SET_NOTES_FETCHING_STATE, payload: true }],
        [],
      );
    });
  });

  describe('fetchDiscussions', () => {
    const discussion = { notes: [] };

    it('updates the discussions and dispatches `updateResolvableDiscussionsCounts`', () => {
      axiosMock.onAny().reply(HTTP_STATUS_OK, { discussion });
      return testAction(
        actions.fetchDiscussions,
        {},
        { noteableType: notesConstants.EPIC_NOTEABLE_TYPE },
        [
          { type: mutationTypes.ADD_OR_UPDATE_DISCUSSIONS, payload: { discussion } },
          { type: mutationTypes.SET_FETCHING_DISCUSSIONS, payload: false },
        ],
        [{ type: 'updateResolvableDiscussionsCounts' }],
      );
    });

    it('dispatches `fetchDiscussionsBatch` action with notes_filter 0 for merge request', () => {
      return testAction(
        actions.fetchDiscussions,
        { path: 'test-path', filter: 'test-filter', persistFilter: 'test-persist-filter' },
        { noteableType: notesConstants.MERGE_REQUEST_NOTEABLE_TYPE },
        [],
        [
          {
            type: 'fetchDiscussionsBatch',
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
      return testAction(
        actions.fetchDiscussions,
        { path: 'test-path', filter: 'test-filter', persistFilter: 'test-persist-filter' },
        { noteableType: notesConstants.ISSUE_NOTEABLE_TYPE },
        [],
        [
          {
            type: 'fetchDiscussionsBatch',
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
      return testAction(
        actions.fetchDiscussions,
        { path: 'test-path', filter: 'test-filter', persistFilter: 'test-persist-filter' },
        { noteableType: notesConstants.MERGE_REQUEST_NOTEABLE_TYPE },
        [],
        [
          {
            type: 'fetchDiscussionsBatch',
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
      axiosMock.onAny().reply(HTTP_STATUS_OK, { discussion }, {});
      return testAction(
        actions.fetchDiscussionsBatch,
        actionPayload,
        null,
        [
          { type: mutationTypes.ADD_OR_UPDATE_DISCUSSIONS, payload: { discussion } },
          { type: mutationTypes.SET_DONE_FETCHING_BATCH_DISCUSSIONS, payload: true },
          { type: mutationTypes.SET_FETCHING_DISCUSSIONS, payload: false },
        ],
        [{ type: 'updateResolvableDiscussionsCounts' }],
      );
    });

    it('dispatches itself if there is `x-next-page-cursor` header', () => {
      axiosMock.onAny().reply(HTTP_STATUS_OK, { discussion }, { 'x-next-page-cursor': 1 });
      return testAction(
        actions.fetchDiscussionsBatch,
        actionPayload,
        null,
        [{ type: mutationTypes.ADD_OR_UPDATE_DISCUSSIONS, payload: { discussion } }],
        [
          {
            type: 'fetchDiscussionsBatch',
            payload: { ...actionPayload, perPage: 30, cursor: 1 },
          },
        ],
      );
    });
  });

  describe('toggleAllDiscussions', () => {
    it('commits SET_EXPAND_ALL_DISCUSSIONS', () => {
      return testAction(
        actions.toggleAllDiscussions,
        undefined,
        { allDiscussionsExpanded: false },
        [{ type: mutationTypes.SET_EXPAND_ALL_DISCUSSIONS, payload: true }],
        [],
      );
    });
  });
});
