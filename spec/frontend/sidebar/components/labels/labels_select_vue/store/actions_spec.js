import MockAdapter from 'axios-mock-adapter';

import testAction from 'helpers/vuex_action_helper';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import * as actions from '~/sidebar/components/labels/labels_select_vue/store/actions';
import * as types from '~/sidebar/components/labels/labels_select_vue/store/mutation_types';
import defaultState from '~/sidebar/components/labels/labels_select_vue/store/state';

jest.mock('~/alert');

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
    it('sets initial store state', () => {
      return testAction(
        actions.setInitialState,
        mockInitialState,
        state,
        [{ type: types.SET_INITIAL_STATE, payload: mockInitialState }],
        [],
      );
    });
  });

  describe('toggleDropdownButton', () => {
    it('toggles dropdown button', () => {
      return testAction(
        actions.toggleDropdownButton,
        {},
        state,
        [{ type: types.TOGGLE_DROPDOWN_BUTTON }],
        [],
      );
    });
  });

  describe('toggleDropdownContents', () => {
    it('toggles dropdown contents', () => {
      return testAction(
        actions.toggleDropdownContents,
        {},
        state,
        [{ type: types.TOGGLE_DROPDOWN_CONTENTS }],
        [],
      );
    });
  });

  describe('toggleDropdownContentsCreateView', () => {
    it('toggles dropdown create view', () => {
      return testAction(
        actions.toggleDropdownContentsCreateView,
        {},
        state,
        [{ type: types.TOGGLE_DROPDOWN_CONTENTS_CREATE_VIEW }],
        [],
      );
    });
  });

  describe('requestLabels', () => {
    it('sets value of `state.labelsFetchInProgress` to `true`', () => {
      return testAction(actions.requestLabels, {}, state, [{ type: types.REQUEST_LABELS }], []);
    });
  });

  describe('receiveLabelsSuccess', () => {
    it('sets provided labels to `state.labels`', () => {
      const labels = [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }];

      return testAction(
        actions.receiveLabelsSuccess,
        labels,
        state,
        [{ type: types.RECEIVE_SET_LABELS_SUCCESS, payload: labels }],
        [],
      );
    });
  });

  describe('receiveLabelsFailure', () => {
    it('sets value `state.labelsFetchInProgress` to `false`', () => {
      return testAction(
        actions.receiveLabelsFailure,
        {},
        state,
        [{ type: types.RECEIVE_SET_LABELS_FAILURE }],
        [],
      );
    });

    it('shows alert error', () => {
      actions.receiveLabelsFailure({ commit: () => {} });

      expect(createAlert).toHaveBeenCalledWith({ message: 'Error fetching labels.' });
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
      it('dispatches `requestLabels` & `receiveLabelsSuccess` actions', () => {
        const labels = [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }];
        mock.onGet(/labels.json/).replyOnce(HTTP_STATUS_OK, labels);

        return testAction(
          actions.fetchLabels,
          {},
          state,
          [],
          [{ type: 'requestLabels' }, { type: 'receiveLabelsSuccess', payload: labels }],
        );
      });
    });

    describe('on failure', () => {
      it('dispatches `requestLabels` & `receiveLabelsFailure` actions', () => {
        mock.onGet(/labels.json/).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});

        return testAction(
          actions.fetchLabels,
          {},
          state,
          [],
          [{ type: 'requestLabels' }, { type: 'receiveLabelsFailure' }],
        );
      });
    });
  });

  describe('requestCreateLabel', () => {
    it('sets value `state.labelCreateInProgress` to `true`', () => {
      return testAction(
        actions.requestCreateLabel,
        {},
        state,
        [{ type: types.REQUEST_CREATE_LABEL }],
        [],
      );
    });
  });

  describe('receiveCreateLabelSuccess', () => {
    it('sets value `state.labelCreateInProgress` to `false`', () => {
      return testAction(
        actions.receiveCreateLabelSuccess,
        {},
        state,
        [{ type: types.RECEIVE_CREATE_LABEL_SUCCESS }],
        [],
      );
    });
  });

  describe('receiveCreateLabelFailure', () => {
    it('sets value `state.labelCreateInProgress` to `false`', () => {
      return testAction(
        actions.receiveCreateLabelFailure,
        {},
        state,
        [{ type: types.RECEIVE_CREATE_LABEL_FAILURE }],
        [],
      );
    });

    it('shows alert error', () => {
      actions.receiveCreateLabelFailure({ commit: () => {} });

      expect(createAlert).toHaveBeenCalledWith({ message: 'Error creating label.' });
    });
  });

  describe('createLabel', () => {
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      state.labelsManagePath = 'labels.json';
    });

    afterEach(() => {
      mock.restore();
    });

    describe('on success', () => {
      it('dispatches `requestCreateLabel`, `fetchLabels` & `receiveCreateLabelSuccess` & `toggleDropdownContentsCreateView` actions', () => {
        const label = { id: 1 };
        mock.onPost(/labels.json/).replyOnce(HTTP_STATUS_OK, label);

        return testAction(
          actions.createLabel,
          {},
          state,
          [],
          [
            { type: 'requestCreateLabel' },
            { payload: { refetch: true }, type: 'fetchLabels' },
            { type: 'receiveCreateLabelSuccess' },
            { type: 'toggleDropdownContentsCreateView' },
          ],
        );
      });
    });

    describe('on failure', () => {
      it('dispatches `requestCreateLabel` & `receiveCreateLabelFailure` actions', () => {
        mock.onPost(/labels.json/).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR, {});

        return testAction(
          actions.createLabel,
          {},
          state,
          [],
          [{ type: 'requestCreateLabel' }, { type: 'receiveCreateLabelFailure' }],
        );
      });
    });
  });

  describe('updateSelectedLabels', () => {
    it('updates `state.labels` based on provided `labels` param', () => {
      const labels = [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }];

      return testAction(
        actions.updateSelectedLabels,
        labels,
        state,
        [{ type: types.UPDATE_SELECTED_LABELS, payload: { labels } }],
        [],
      );
    });
  });

  describe('updateLabelsSetState', () => {
    it('updates labels `set` state to match `selectedLabels`', () => {
      return testAction(
        actions.updateLabelsSetState,
        {},
        state,
        [{ type: types.UPDATE_LABELS_SET_STATE }],
        [],
      );
    });
  });
});
