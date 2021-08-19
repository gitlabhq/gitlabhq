import testAction from 'helpers/vuex_action_helper';
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
