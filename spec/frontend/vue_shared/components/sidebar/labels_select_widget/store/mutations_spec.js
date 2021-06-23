import * as types from '~/vue_shared/components/sidebar/labels_select_widget/store/mutation_types';
import mutations from '~/vue_shared/components/sidebar/labels_select_widget/store/mutations';

describe('LabelsSelect Mutations', () => {
  describe(`${types.SET_INITIAL_STATE}`, () => {
    it('initializes provided props to store state', () => {
      const state = {};
      mutations[types.SET_INITIAL_STATE](state, {
        labels: 'foo',
      });

      expect(state.labels).toEqual('foo');
    });
  });

  describe(`${types.TOGGLE_DROPDOWN_BUTTON}`, () => {
    it('toggles value of `state.showDropdownButton`', () => {
      const state = {
        showDropdownButton: false,
      };
      mutations[types.TOGGLE_DROPDOWN_BUTTON](state);

      expect(state.showDropdownButton).toBe(true);
    });
  });

  describe(`${types.TOGGLE_DROPDOWN_CONTENTS}`, () => {
    it('toggles value of `state.showDropdownButton` when `state.dropdownOnly` is false', () => {
      const state = {
        dropdownOnly: false,
        showDropdownButton: false,
        variant: 'sidebar',
      };
      mutations[types.TOGGLE_DROPDOWN_CONTENTS](state);

      expect(state.showDropdownButton).toBe(true);
    });

    it('toggles value of `state.showDropdownContents`', () => {
      const state = {
        showDropdownContents: false,
      };
      mutations[types.TOGGLE_DROPDOWN_CONTENTS](state);

      expect(state.showDropdownContents).toBe(true);
    });

    it('sets value of `state.showDropdownContentsCreateView` to `false` when `showDropdownContents` is true', () => {
      const state = {
        showDropdownContents: false,
        showDropdownContentsCreateView: true,
      };
      mutations[types.TOGGLE_DROPDOWN_CONTENTS](state);

      expect(state.showDropdownContentsCreateView).toBe(false);
    });
  });

  describe(`${types.TOGGLE_DROPDOWN_CONTENTS_CREATE_VIEW}`, () => {
    it('toggles value of `state.showDropdownContentsCreateView`', () => {
      const state = {
        showDropdownContentsCreateView: false,
      };
      mutations[types.TOGGLE_DROPDOWN_CONTENTS_CREATE_VIEW](state);

      expect(state.showDropdownContentsCreateView).toBe(true);
    });
  });

  describe(`${types.REQUEST_LABELS}`, () => {
    it('sets value of `state.labelsFetchInProgress` to true', () => {
      const state = {
        labelsFetchInProgress: false,
      };
      mutations[types.REQUEST_LABELS](state);

      expect(state.labelsFetchInProgress).toBe(true);
    });
  });

  describe(`${types.RECEIVE_SET_LABELS_SUCCESS}`, () => {
    const selectedLabels = [{ id: 2 }, { id: 4 }];
    const labels = [{ id: 1 }, { id: 2 }, { id: 3 }, { id: 4 }];

    it('sets value of `state.labelsFetchInProgress` to false', () => {
      const state = {
        selectedLabels,
        labelsFetchInProgress: true,
      };
      mutations[types.RECEIVE_SET_LABELS_SUCCESS](state, labels);

      expect(state.labelsFetchInProgress).toBe(false);
    });

    it('sets provided `labels` to `state.labels` along with `set` prop based on `state.selectedLabels`', () => {
      const selectedLabelIds = selectedLabels.map((label) => label.id);
      const state = {
        selectedLabels,
        labelsFetchInProgress: true,
      };
      mutations[types.RECEIVE_SET_LABELS_SUCCESS](state, labels);

      state.labels.forEach((label) => {
        if (selectedLabelIds.includes(label.id)) {
          expect(label.set).toBe(true);
        }
      });
    });
  });

  describe(`${types.RECEIVE_SET_LABELS_FAILURE}`, () => {
    it('sets value of `state.labelsFetchInProgress` to false', () => {
      const state = {
        labelsFetchInProgress: true,
      };
      mutations[types.RECEIVE_SET_LABELS_FAILURE](state);

      expect(state.labelsFetchInProgress).toBe(false);
    });
  });

  describe(`${types.UPDATE_SELECTED_LABELS}`, () => {
    let labels;

    beforeEach(() => {
      labels = [
        { id: 1, title: 'scoped::test', set: true },
        { id: 2, set: false, title: 'scoped::one' },
        { id: 3, title: '' },
        { id: 4, title: '' },
      ];
    });

    it('updates `state.labels` to include `touched` and `set` props based on provided `labels` param', () => {
      const updatedLabelIds = [2];
      const state = {
        labels,
      };
      mutations[types.UPDATE_SELECTED_LABELS](state, { labels: [{ id: 2 }] });

      state.labels.forEach((label) => {
        if (updatedLabelIds.includes(label.id)) {
          expect(label.touched).toBe(true);
          expect(label.set).toBe(true);
        }
      });
    });

    describe('when label is scoped', () => {
      it('unsets the currently selected scoped label and sets the current label', () => {
        const state = {
          labels,
        };
        mutations[types.UPDATE_SELECTED_LABELS](state, {
          labels: [{ id: 2, title: 'scoped::one' }],
        });

        expect(state.labels).toEqual([
          { id: 1, title: 'scoped::test', set: false },
          { id: 2, set: true, title: 'scoped::one', touched: true },
          { id: 3, title: '' },
          { id: 4, title: '' },
        ]);
      });
    });
  });
});
