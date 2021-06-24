import AxiosMockAdapter from 'axios-mock-adapter';
import testAction from 'helpers/vuex_action_helper';
import { TEST_HOST } from 'spec/test_constants';
import Api from '~/api';
import createFlash from '~/flash';
import { EVENT_ISSUABLE_VUE_APP_CHANGE } from '~/issuable/constants';
import axios from '~/lib/utils/axios_utils';
import * as notesConstants from '~/notes/constants';
import createStore from '~/notes/stores';
import * as actions from '~/notes/stores/actions';
import * as mutationTypes from '~/notes/stores/mutation_types';
import mutations from '~/notes/stores/mutations';
import * as utils from '~/notes/stores/utils';
import updateIssueLockMutation from '~/sidebar/components/lock/mutations/update_issue_lock.mutation.graphql';
import updateMergeRequestLockMutation from '~/sidebar/components/lock/mutations/update_merge_request_lock.mutation.graphql';
import mrWidgetEventHub from '~/vue_merge_request_widget/event_hub';
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
const mockFlashClose = jest.fn();
jest.mock('~/flash', () => {
  const flash = jest.fn().mockImplementation(() => {
    return {
      close: mockFlashClose,
    };
  });

  return flash;
});

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
    setFixtures(
      '<div class="detail-page-header-actions"><button class="btn-close btn-grouped"></button></div>',
    );
  });

  afterEach(() => {
    resetStore(store);
    axiosMock.restore();
  });

  describe('setNotesData', () => {
    it('should set received notes data', (done) => {
      testAction(
        actions.setNotesData,
        notesDataMock,
        { notesData: {} },
        [{ type: 'SET_NOTES_DATA', payload: notesDataMock }],
        [],
        done,
      );
    });
  });

  describe('setNoteableData', () => {
    it('should set received issue data', (done) => {
      testAction(
        actions.setNoteableData,
        noteableDataMock,
        { noteableData: {} },
        [{ type: 'SET_NOTEABLE_DATA', payload: noteableDataMock }],
        [],
        done,
      );
    });
  });

  describe('setUserData', () => {
    it('should set received user data', (done) => {
      testAction(
        actions.setUserData,
        userDataMock,
        { userData: {} },
        [{ type: 'SET_USER_DATA', payload: userDataMock }],
        [],
        done,
      );
    });
  });

  describe('setLastFetchedAt', () => {
    it('should set received timestamp', (done) => {
      testAction(
        actions.setLastFetchedAt,
        'timestamp',
        { lastFetchedAt: {} },
        [{ type: 'SET_LAST_FETCHED_AT', payload: 'timestamp' }],
        [],
        done,
      );
    });
  });

  describe('setInitialNotes', () => {
    it('should set initial notes', (done) => {
      testAction(
        actions.setInitialNotes,
        [individualNote],
        { notes: [] },
        [{ type: 'SET_INITIAL_DISCUSSIONS', payload: [individualNote] }],
        [],
        done,
      );
    });
  });

  describe('setTargetNoteHash', () => {
    it('should set target note hash', (done) => {
      testAction(
        actions.setTargetNoteHash,
        'hash',
        { notes: [] },
        [{ type: 'SET_TARGET_NOTE_HASH', payload: 'hash' }],
        [],
        done,
      );
    });
  });

  describe('toggleDiscussion', () => {
    it('should toggle discussion', (done) => {
      testAction(
        actions.toggleDiscussion,
        { discussionId: discussionMock.id },
        { notes: [discussionMock] },
        [{ type: 'TOGGLE_DISCUSSION', payload: { discussionId: discussionMock.id } }],
        [],
        done,
      );
    });
  });

  describe('expandDiscussion', () => {
    it('should expand discussion', (done) => {
      testAction(
        actions.expandDiscussion,
        { discussionId: discussionMock.id },
        { notes: [discussionMock] },
        [{ type: 'EXPAND_DISCUSSION', payload: { discussionId: discussionMock.id } }],
        [{ type: 'diffs/renderFileForDiscussionId', payload: discussionMock.id }],
        done,
      );
    });
  });

  describe('collapseDiscussion', () => {
    it('should commit collapse discussion', (done) => {
      testAction(
        actions.collapseDiscussion,
        { discussionId: discussionMock.id },
        { notes: [discussionMock] },
        [{ type: 'COLLAPSE_DISCUSSION', payload: { discussionId: discussionMock.id } }],
        [],
        done,
      );
    });
  });

  describe('async methods', () => {
    beforeEach(() => {
      axiosMock.onAny().reply(200, {});
    });

    describe('closeMergeRequest', () => {
      it('sets state as closed', (done) => {
        store
          .dispatch('closeIssuable', { notesData: { closeIssuePath: '' } })
          .then(() => {
            expect(store.state.noteableData.state).toEqual('closed');
            expect(store.state.isToggleStateButtonLoading).toEqual(false);
            done();
          })
          .catch(done.fail);
      });
    });

    describe('reopenMergeRequest', () => {
      it('sets state as reopened', (done) => {
        store
          .dispatch('reopenIssuable', { notesData: { reopenIssuePath: '' } })
          .then(() => {
            expect(store.state.noteableData.state).toEqual('reopened');
            expect(store.state.isToggleStateButtonLoading).toEqual(false);
            done();
          })
          .catch(done.fail);
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
    it('should set loading as true', (done) => {
      testAction(
        actions.toggleStateButtonLoading,
        true,
        {},
        [{ type: 'TOGGLE_STATE_BUTTON_LOADING', payload: true }],
        [],
        done,
      );
    });

    it('should set loading as false', (done) => {
      testAction(
        actions.toggleStateButtonLoading,
        false,
        {},
        [{ type: 'TOGGLE_STATE_BUTTON_LOADING', payload: false }],
        [],
        done,
      );
    });
  });

  describe('toggleIssueLocalState', () => {
    it('sets issue state as closed', (done) => {
      testAction(actions.toggleIssueLocalState, 'closed', {}, [{ type: 'CLOSE_ISSUE' }], [], done);
    });

    it('sets issue state as reopened', (done) => {
      testAction(
        actions.toggleIssueLocalState,
        'reopened',
        {},
        [{ type: 'REOPEN_ISSUE' }],
        [],
        done,
      );
    });
  });

  describe('poll', () => {
    const pollInterval = 6000;
    const pollResponse = { notes: [], last_fetched_at: '123456' };
    const pollHeaders = { 'poll-interval': `${pollInterval}` };
    const successMock = () =>
      axiosMock.onGet(notesDataMock.notesPath).reply(200, pollResponse, pollHeaders);
    const failureMock = () => axiosMock.onGet(notesDataMock.notesPath).reply(500);
    const advanceAndRAF = async (time) => {
      if (time) {
        jest.advanceTimersByTime(time);
      }

      return new Promise((resolve) => requestAnimationFrame(resolve));
    };
    const advanceXMoreIntervals = async (number) => {
      const timeoutLength = pollInterval * number;

      return advanceAndRAF(timeoutLength);
    };
    const startPolling = async () => {
      await store.dispatch('poll');
      await advanceAndRAF(2);
    };
    const cleanUp = async () => {
      jest.clearAllTimers();

      return store.dispatch('stopPolling');
    };

    beforeEach((done) => {
      store.dispatch('setNotesData', notesDataMock).then(done).catch(done.fail);
    });

    afterEach(() => {
      return cleanUp();
    });

    it('calls service with last fetched state', async () => {
      successMock();

      await startPolling();

      expect(store.state.lastFetchedAt).toBe('123456');

      await advanceXMoreIntervals(1);

      expect(axiosMock.history.get).toHaveLength(2);
      expect(axiosMock.history.get[1].headers).toMatchObject({
        'X-Last-Fetched-At': '123456',
      });
    });

    describe('polling side effects', () => {
      it('retries twice', async () => {
        failureMock();

        await startPolling();

        // This is the first request, not a retry
        expect(axiosMock.history.get).toHaveLength(1);

        await advanceXMoreIntervals(1);

        // Retry #1
        expect(axiosMock.history.get).toHaveLength(2);

        await advanceXMoreIntervals(1);

        // Retry #2
        expect(axiosMock.history.get).toHaveLength(3);

        await advanceXMoreIntervals(10);

        // There are no more retries
        expect(axiosMock.history.get).toHaveLength(3);
      });

      it('shows the error display on the second failure', async () => {
        failureMock();

        await startPolling();

        expect(axiosMock.history.get).toHaveLength(1);
        expect(createFlash).not.toHaveBeenCalled();

        await advanceXMoreIntervals(1);

        expect(axiosMock.history.get).toHaveLength(2);
        expect(createFlash).toHaveBeenCalled();
        expect(createFlash).toHaveBeenCalledTimes(1);
      });

      it('resets the failure counter on success', async () => {
        // We can't get access to the actual counter in the polling closure.
        // So we can infer that it's reset by ensuring that the error is only
        //  shown when we cause two failures in a row - no successes between

        axiosMock
          .onGet(notesDataMock.notesPath)
          .replyOnce(500) // cause one error
          .onGet(notesDataMock.notesPath)
          .replyOnce(200, pollResponse, pollHeaders) // then a success
          .onGet(notesDataMock.notesPath)
          .reply(500); // and then more errors

        await startPolling(); // Failure #1
        await advanceXMoreIntervals(1); // Success #1
        await advanceXMoreIntervals(1); // Failure #2

        // That was the first failure AFTER a success, so we should NOT see the error displayed
        expect(createFlash).not.toHaveBeenCalled();

        // Now we'll allow another failure
        await advanceXMoreIntervals(1); // Failure #3

        // Since this is the second failure in a row, the error should happen
        expect(createFlash).toHaveBeenCalled();
        expect(createFlash).toHaveBeenCalledTimes(1);
      });

      it('hides the error display if it exists on success', async () => {
        jest.mock();
        failureMock();

        await startPolling();
        await advanceXMoreIntervals(2);

        // After two errors, the error should be displayed
        expect(createFlash).toHaveBeenCalled();
        expect(createFlash).toHaveBeenCalledTimes(1);

        axiosMock.reset();
        successMock();

        await advanceXMoreIntervals(1);

        expect(mockFlashClose).toHaveBeenCalled();
        expect(mockFlashClose).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('setNotesFetchedState', () => {
    it('should set notes fetched state', (done) => {
      testAction(
        actions.setNotesFetchedState,
        true,
        {},
        [{ type: 'SET_NOTES_FETCHED_STATE', payload: true }],
        [],
        done,
      );
    });
  });

  describe('removeNote', () => {
    const endpoint = `${TEST_HOST}/note`;

    beforeEach(() => {
      axiosMock.onDelete(endpoint).replyOnce(200, {});

      document.body.setAttribute('data-page', '');
    });

    afterEach(() => {
      axiosMock.restore();

      document.body.setAttribute('data-page', '');
    });

    it('commits DELETE_NOTE and dispatches updateMergeRequestWidget', (done) => {
      const note = { path: endpoint, id: 1 };

      testAction(
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
        done,
      );
    });

    it('dispatches removeDiscussionsFromDiff on merge request page', (done) => {
      const note = { path: endpoint, id: 1 };

      document.body.setAttribute('data-page', 'projects:merge_requests:show');

      testAction(
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
        done,
      );
    });
  });

  describe('deleteNote', () => {
    const endpoint = `${TEST_HOST}/note`;

    beforeEach(() => {
      axiosMock.onDelete(endpoint).replyOnce(200, {});

      document.body.setAttribute('data-page', '');
    });

    afterEach(() => {
      axiosMock.restore();

      document.body.setAttribute('data-page', '');
    });

    it('dispatches removeNote', (done) => {
      const note = { path: endpoint, id: 1 };

      testAction(
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
        done,
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
        axiosMock.onAny().reply(200, res);
      });

      it('commits ADD_NEW_NOTE and dispatches updateMergeRequestWidget', (done) => {
        testAction(
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
          done,
        );
      });
    });

    describe('error', () => {
      const res = {
        errors: ['error'],
      };

      beforeEach(() => {
        axiosMock.onAny().replyOnce(200, res);
      });

      it('does not commit ADD_NEW_NOTE or dispatch updateMergeRequestWidget', (done) => {
        testAction(
          actions.createNewNote,
          { endpoint: `${TEST_HOST}`, data: {} },
          store.state,
          [],
          [],
          done,
        );
      });
    });
  });

  describe('toggleResolveNote', () => {
    const res = {
      resolved: true,
    };

    beforeEach(() => {
      axiosMock.onAny().reply(200, res);
    });

    describe('as note', () => {
      it('commits UPDATE_NOTE and dispatches updateMergeRequestWidget', (done) => {
        testAction(
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
          done,
        );
      });
    });

    describe('as discussion', () => {
      it('commits UPDATE_DISCUSSION and dispatches updateMergeRequestWidget', (done) => {
        testAction(
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
          done,
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
    it('should set comments disabled state', (done) => {
      testAction(
        actions.setCommentsDisabled,
        true,
        null,
        [{ type: 'DISABLE_COMMENTS', payload: true }],
        [],
        done,
      );
    });
  });

  describe('updateResolvableDiscussionsCounts', () => {
    it('commits UPDATE_RESOLVABLE_DISCUSSIONS_COUNTS', (done) => {
      testAction(
        actions.updateResolvableDiscussionsCounts,
        null,
        {},
        [{ type: 'UPDATE_RESOLVABLE_DISCUSSIONS_COUNTS' }],
        [],
        done,
      );
    });
  });

  describe('convertToDiscussion', () => {
    it('commits CONVERT_TO_DISCUSSION with noteId', (done) => {
      const noteId = 'dummy-note-id';
      testAction(
        actions.convertToDiscussion,
        noteId,
        {},
        [{ type: 'CONVERT_TO_DISCUSSION', payload: noteId }],
        [],
        done,
      );
    });
  });

  describe('updateOrCreateNotes', () => {
    it('Prevents `fetchDiscussions` being called multiple times within time limit', () => {
      jest.useFakeTimers();
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

      jest.runAllTimers();
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

    it('updates discussion if response contains disussion', (done) => {
      const discussion = { notes: [] };
      axiosMock.onAny().reply(200, { discussion });

      testAction(
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
        done,
      );
    });

    it('adds a reply to a discussion', (done) => {
      const res = {};
      axiosMock.onAny().reply(200, res);

      testAction(
        actions.replyToDiscussion,
        payload,
        {
          notesById: {},
        },
        [{ type: mutationTypes.ADD_NEW_REPLY_TO_DISCUSSION, payload: res }],
        [],
        done,
      );
    });
  });

  describe('removeConvertedDiscussion', () => {
    it('commits CONVERT_TO_DISCUSSION with noteId', (done) => {
      const noteId = 'dummy-id';
      testAction(
        actions.removeConvertedDiscussion,
        noteId,
        {},
        [{ type: 'REMOVE_CONVERTED_DISCUSSION', payload: noteId }],
        [],
        done,
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

    it('when unresolved, dispatches action', (done) => {
      testAction(
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
        done,
      );
    });

    it('when resolved, does nothing', (done) => {
      getters.isDiscussionResolved = (id) => id === discussionId;

      testAction(
        actions.resolveDiscussion,
        { discussionId },
        { ...state, ...getters },
        [],
        [],
        done,
      );
    });
  });

  describe('saveNote', () => {
    const flashContainer = {};
    const payload = { endpoint: TEST_HOST, data: { 'note[note]': 'some text' }, flashContainer };

    describe('if response contains errors', () => {
      const res = { errors: { something: ['went wrong'] } };
      const error = { message: 'Unprocessable entity', response: { data: res } };

      it('throws an error', (done) => {
        actions
          .saveNote(
            {
              commit() {},
              dispatch: () => Promise.reject(error),
            },
            payload,
          )
          .then(() => done.fail('Expected error to be thrown!'))
          .catch((err) => {
            expect(err).toBe(error);
            expect(createFlash).not.toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('if response contains errors.base', () => {
      const res = { errors: { base: ['something went wrong'] } };
      const error = { message: 'Unprocessable entity', response: { data: res } };

      it('sets flash alert using errors.base message', (done) => {
        actions
          .saveNote(
            {
              commit() {},
              dispatch: () => Promise.reject(error),
            },
            { ...payload, flashContainer },
          )
          .then((resp) => {
            expect(resp.hasFlash).toBe(true);
            expect(createFlash).toHaveBeenCalledWith({
              message: 'Your comment could not be submitted because something went wrong',
              parent: flashContainer,
            });
          })
          .catch(() => done.fail('Expected success response!'))
          .then(done)
          .catch(done.fail);
      });
    });

    describe('if response contains no errors', () => {
      const res = { valid: true };

      it('returns the response', (done) => {
        actions
          .saveNote(
            {
              commit() {},
              dispatch: () => Promise.resolve(res),
            },
            payload,
          )
          .then((data) => {
            expect(data).toBe(res);
            expect(createFlash).not.toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
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

    const testSubmitSuggestion = (done, expectFn) => {
      actions
        .submitSuggestion(
          { commit, dispatch },
          { discussionId, noteId, suggestionId, flashContainer },
        )
        .then(expectFn)
        .then(done)
        .catch(done.fail);
    };

    it('when service success, commits and resolves discussion', (done) => {
      testSubmitSuggestion(done, () => {
        expect(commit.mock.calls).toEqual([
          [mutationTypes.SET_RESOLVING_DISCUSSION, true],
          [mutationTypes.SET_RESOLVING_DISCUSSION, false],
        ]);

        expect(dispatch.mock.calls).toEqual([
          ['stopPolling'],
          ['resolveDiscussion', { discussionId }],
          ['restartPolling'],
        ]);
        expect(createFlash).not.toHaveBeenCalled();
      });
    });

    it('when service fails, flashes error message', (done) => {
      const response = { response: { data: { message: TEST_ERROR_MESSAGE } } };

      Api.applySuggestion.mockReturnValue(Promise.reject(response));

      testSubmitSuggestion(done, () => {
        expect(commit.mock.calls).toEqual([
          [mutationTypes.SET_RESOLVING_DISCUSSION, true],
          [mutationTypes.SET_RESOLVING_DISCUSSION, false],
        ]);
        expect(dispatch.mock.calls).toEqual([['stopPolling'], ['restartPolling']]);
        expect(createFlash).toHaveBeenCalledWith({
          message: TEST_ERROR_MESSAGE,
          parent: flashContainer,
        });
      });
    });

    it('when service fails, and no error message available, uses default message', (done) => {
      const response = { response: 'foo' };

      Api.applySuggestion.mockReturnValue(Promise.reject(response));

      testSubmitSuggestion(done, () => {
        expect(commit.mock.calls).toEqual([
          [mutationTypes.SET_RESOLVING_DISCUSSION, true],
          [mutationTypes.SET_RESOLVING_DISCUSSION, false],
        ]);
        expect(dispatch.mock.calls).toEqual([['stopPolling'], ['restartPolling']]);
        expect(createFlash).toHaveBeenCalledWith({
          message: 'Something went wrong while applying the suggestion. Please try again.',
          parent: flashContainer,
        });
      });
    });

    it('when resolve discussion fails, fail gracefully', (done) => {
      dispatch.mockReturnValue(Promise.reject());

      testSubmitSuggestion(done, () => {
        expect(createFlash).not.toHaveBeenCalled();
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

    const testSubmitSuggestionBatch = (done, expectFn) => {
      actions
        .submitSuggestionBatch({ commit, dispatch, state }, { flashContainer })
        .then(expectFn)
        .then(done)
        .catch(done.fail);
    };

    it('when service succeeds, commits, resolves discussions, resets batch and applying batch state', (done) => {
      testSubmitSuggestionBatch(done, () => {
        expect(commit.mock.calls).toEqual([
          [mutationTypes.SET_APPLYING_BATCH_STATE, true],
          [mutationTypes.SET_RESOLVING_DISCUSSION, true],
          [mutationTypes.CLEAR_SUGGESTION_BATCH],
          [mutationTypes.SET_APPLYING_BATCH_STATE, false],
          [mutationTypes.SET_RESOLVING_DISCUSSION, false],
        ]);

        expect(dispatch.mock.calls).toEqual([
          ['stopPolling'],
          ['resolveDiscussion', { discussionId: discussionIds[0] }],
          ['resolveDiscussion', { discussionId: discussionIds[1] }],
          ['restartPolling'],
        ]);

        expect(createFlash).not.toHaveBeenCalled();
      });
    });

    it('when service fails, flashes error message, resets applying batch state', (done) => {
      const response = { response: { data: { message: TEST_ERROR_MESSAGE } } };

      Api.applySuggestionBatch.mockReturnValue(Promise.reject(response));

      testSubmitSuggestionBatch(done, () => {
        expect(commit.mock.calls).toEqual([
          [mutationTypes.SET_APPLYING_BATCH_STATE, true],
          [mutationTypes.SET_RESOLVING_DISCUSSION, true],
          [mutationTypes.SET_APPLYING_BATCH_STATE, false],
          [mutationTypes.SET_RESOLVING_DISCUSSION, false],
        ]);

        expect(dispatch.mock.calls).toEqual([['stopPolling'], ['restartPolling']]);
        expect(createFlash).toHaveBeenCalledWith({
          message: TEST_ERROR_MESSAGE,
          parent: flashContainer,
        });
      });
    });

    it('when service fails, and no error message available, uses default message', (done) => {
      const response = { response: 'foo' };

      Api.applySuggestionBatch.mockReturnValue(Promise.reject(response));

      testSubmitSuggestionBatch(done, () => {
        expect(commit.mock.calls).toEqual([
          [mutationTypes.SET_APPLYING_BATCH_STATE, true],
          [mutationTypes.SET_RESOLVING_DISCUSSION, true],
          [mutationTypes.SET_APPLYING_BATCH_STATE, false],
          [mutationTypes.SET_RESOLVING_DISCUSSION, false],
        ]);

        expect(dispatch.mock.calls).toEqual([['stopPolling'], ['restartPolling']]);
        expect(createFlash).toHaveBeenCalledWith({
          message:
            'Something went wrong while applying the batch of suggestions. Please try again.',
          parent: flashContainer,
        });
      });
    });

    it('when resolve discussions fails, fails gracefully, resets batch and applying batch state', (done) => {
      dispatch.mockReturnValue(Promise.reject());

      testSubmitSuggestionBatch(done, () => {
        expect(commit.mock.calls).toEqual([
          [mutationTypes.SET_APPLYING_BATCH_STATE, true],
          [mutationTypes.SET_RESOLVING_DISCUSSION, true],
          [mutationTypes.CLEAR_SUGGESTION_BATCH],
          [mutationTypes.SET_APPLYING_BATCH_STATE, false],
          [mutationTypes.SET_RESOLVING_DISCUSSION, false],
        ]);

        expect(createFlash).not.toHaveBeenCalled();
      });
    });
  });

  describe('addSuggestionInfoToBatch', () => {
    const suggestionInfo = batchSuggestionsInfoMock[0];

    it("adds a suggestion's info to the current batch", (done) => {
      testAction(
        actions.addSuggestionInfoToBatch,
        suggestionInfo,
        { batchSuggestionsInfo: [] },
        [{ type: 'ADD_SUGGESTION_TO_BATCH', payload: suggestionInfo }],
        [],
        done,
      );
    });
  });

  describe('removeSuggestionInfoFromBatch', () => {
    const suggestionInfo = batchSuggestionsInfoMock[0];

    it("removes a suggestion's info the current batch", (done) => {
      testAction(
        actions.removeSuggestionInfoFromBatch,
        suggestionInfo.suggestionId,
        { batchSuggestionsInfo: [suggestionInfo] },
        [{ type: 'REMOVE_SUGGESTION_FROM_BATCH', payload: suggestionInfo.suggestionId }],
        [],
        done,
      );
    });
  });

  describe('filterDiscussion', () => {
    const path = 'some-discussion-path';
    const filter = 0;

    beforeEach(() => {
      dispatch.mockReturnValue(new Promise(() => {}));
    });

    it('fetches discussions with filter and persistFilter false', () => {
      actions.filterDiscussion({ dispatch }, { path, filter, persistFilter: false });

      expect(dispatch.mock.calls).toEqual([
        ['setLoadingState', true],
        ['fetchDiscussions', { path, filter, persistFilter: false }],
      ]);
    });

    it('fetches discussions with filter and persistFilter true', () => {
      actions.filterDiscussion({ dispatch }, { path, filter, persistFilter: true });

      expect(dispatch.mock.calls).toEqual([
        ['setLoadingState', true],
        ['fetchDiscussions', { path, filter, persistFilter: true }],
      ]);
    });
  });

  describe('setDiscussionSortDirection', () => {
    it('calls the correct mutation with the correct args', (done) => {
      testAction(
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
        done,
      );
    });
  });

  describe('setSelectedCommentPosition', () => {
    it('calls the correct mutation with the correct args', (done) => {
      testAction(
        actions.setSelectedCommentPosition,
        {},
        {},
        [{ type: mutationTypes.SET_SELECTED_COMMENT_POSITION, payload: {} }],
        [],
        done,
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
      it('dispatches requestDeleteDescriptionVersion', (done) => {
        axiosMock.onDelete(endpoint).replyOnce(200);
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
              type: 'receiveDeleteDescriptionVersion',
              payload: payload.versionId,
            },
          ],
          done,
        );
      });
    });

    describe('if response contains errors', () => {
      const errorMessage = 'Request failed with status code 503';
      it('dispatches receiveDeleteDescriptionVersionError and throws an error', (done) => {
        axiosMock.onDelete(endpoint).replyOnce(503);
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
        )
          .then(() => done.fail('Expected error to be thrown'))
          .catch(() => {
            expect(createFlash).toHaveBeenCalled();
            done();
          });
      });
    });
  });

  describe('setConfidentiality', () => {
    it('calls the correct mutation with the correct args', () => {
      testAction(actions.setConfidentiality, true, { noteableData: { confidential: false } }, [
        { type: mutationTypes.SET_ISSUE_CONFIDENTIAL, payload: true },
      ]);
    });
  });

  describe('updateAssignees', () => {
    it('update the assignees state', (done) => {
      testAction(
        actions.updateAssignees,
        [userDataMock.id],
        { state: noteableDataMock },
        [{ type: mutationTypes.UPDATE_ASSIGNEES, payload: [userDataMock.id] }],
        [],
        done,
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
    it('update the assignees state', (done) => {
      const updatedPosition = { discussionId: 1, position: { test: true } };
      testAction(
        actions.updateDiscussionPosition,
        updatedPosition,
        { state: { discussions: [] } },
        [{ type: mutationTypes.UPDATE_DISCUSSION_POSITION, payload: updatedPosition }],
        [],
        done,
      );
    });
  });

  describe('setFetchingState', () => {
    it('commits SET_NOTES_FETCHING_STATE', (done) => {
      testAction(
        actions.setFetchingState,
        true,
        null,
        [{ type: mutationTypes.SET_NOTES_FETCHING_STATE, payload: true }],
        [],
        done,
      );
    });
  });
});
