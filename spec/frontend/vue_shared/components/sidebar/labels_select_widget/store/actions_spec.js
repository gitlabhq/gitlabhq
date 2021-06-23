import MockAdapter from 'axios-mock-adapter';

import testAction from 'helpers/vuex_action_helper';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import * as actions from '~/vue_shared/components/sidebar/labels_select_widget/store/actions';
import * as types from '~/vue_shared/components/sidebar/labels_select_widget/store/mutation_types';
import defaultState from '~/vue_shared/components/sidebar/labels_select_widget/store/state';

jest.mock('~/flash');

describe('LabelsSelect Actions', () => {
  let state;
  const mockInitialState = {
    labels: [],
    selectedLabels: [],
  };

  beforeEach(() => {
    state = { ...defaultState() };
  });

  describe('setInitialState', () => {
    it('sets initial store state', (done) => {
      testAction(
        actions.setInitialState,
        mockInitialState,
        state,
        [{ type: types.SET_INITIAL_STATE, payload: mockInitialState }],
        [],
        done,
      );
    });
  });

  describe('toggleDropdownButton', () => {
    it('toggles dropdown button', (done) => {
      testAction(
        actions.toggleDropdownButton,
        {},
        state,
        [{ type: types.TOGGLE_DROPDOWN_BUTTON }],
        [],
        done,
      );
    });
  });

  describe('toggleDropdownContents', () => {
    it('toggles dropdown contents', (done) => {
      testAction(
        actions.toggleDropdownContents,
        {},
        state,
        [{ type: types.TOGGLE_DROPDOWN_CONTENTS }],
        [],
        done,
      );
    });
  });

  describe('toggleDropdownContentsCreateView', () => {
    it('toggles dropdown create view', (done) => {
      testAction(
        actions.toggleDropdownContentsCreateView,
        {},
        state,
        [{ type: types.TOGGLE_DROPDOWN_CONTENTS_CREATE_VIEW }],
        [],
        done,
      );
    });
  });

  describe('requestLabels', () => {
    it('sets value of `state.labelsFetchInProgress` to `true`', (done) => {
      testAction(actions.requestLabels, {}, state, [{ type: types.REQUEST_LABELS }], [], done);
    });
  });

  describe('receiveLabelsSuccess', () => {
    it('sets provided labels to `state.labels`', (done) => {
      const labels = [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }];

      testAction(
        actions.receiveLabelsSuccess,
        labels,
        state,
        [{ type: types.RECEIVE_SET_LABELS_SUCCESS, payload: labels }],
        [],
        done,
      );
    });
  });

  describe('receiveLabelsFailure', () => {
    it('sets value `state.labelsFetchInProgress` to `false`', (done) => {
      testAction(
        actions.receiveLabelsFailure,
        {},
        state,
        [{ type: types.RECEIVE_SET_LABELS_FAILURE }],
        [],
        done,
      );
    });

    it('shows flash error', () => {
      actions.receiveLabelsFailure({ commit: () => {} });

      expect(createFlash).toHaveBeenCalledWith({ message: 'Error fetching labels.' });
    });
  });

  describe('fetchLabels', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      state.labelsFetchPath = 'labels.json';
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      it('dispatches `requestLabels` & `receiveLabelsSuccess` actions', (done) => {
        const labels = [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }];
        mock.onGet(/labels.json/).replyOnce(200, labels);

        testAction(
          actions.fetchLabels,
          {},
          state,
          [],
          [{ type: 'requestLabels' }, { type: 'receiveLabelsSuccess', payload: labels }],
          done,
        );
      });
    });

    describe('on failure', () => {
      it('dispatches `requestLabels` & `receiveLabelsFailure` actions', (done) => {
        mock.onGet(/labels.json/).replyOnce(500, {});

        testAction(
          actions.fetchLabels,
          {},
          state,
          [],
          [{ type: 'requestLabels' }, { type: 'receiveLabelsFailure' }],
          done,
        );
      });
    });
  });

  describe('updateSelectedLabels', () => {
    it('updates `state.labels` based on provided `labels` param', (done) => {
      const labels = [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }];

      testAction(
        actions.updateSelectedLabels,
        labels,
        state,
        [{ type: types.UPDATE_SELECTED_LABELS, payload: { labels } }],
        [],
        done,
      );
    });
  });
});
