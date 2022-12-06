import { cloneDeep } from 'lodash';
import * as types from '~/sidebar/components/labels/labels_select_vue/store/mutation_types';
import mutations from '~/sidebar/components/labels/labels_select_vue/store/mutations';

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
    const selectedLabels = [
      { id: 2, set: true },
      { id: 4, set: true },
    ];
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

  describe(`${types.REQUEST_CREATE_LABEL}`, () => {
    it('sets value of `state.labelCreateInProgress` to true', () => {
      const state = {
        labelCreateInProgress: false,
      };
      mutations[types.REQUEST_CREATE_LABEL](state);

      expect(state.labelCreateInProgress).toBe(true);
    });
  });

  describe(`${types.RECEIVE_CREATE_LABEL_SUCCESS}`, () => {
    it('sets value of `state.labelCreateInProgress` to false', () => {
      const state = {
        labelCreateInProgress: false,
      };
      mutations[types.RECEIVE_CREATE_LABEL_SUCCESS](state);

      expect(state.labelCreateInProgress).toBe(false);
    });
  });

  describe(`${types.RECEIVE_CREATE_LABEL_FAILURE}`, () => {
    it('sets value of `state.labelCreateInProgress` to false', () => {
      const state = {
        labelCreateInProgress: false,
      };
      mutations[types.RECEIVE_CREATE_LABEL_FAILURE](state);

      expect(state.labelCreateInProgress).toBe(false);
    });
  });

  describe(`${types.UPDATE_SELECTED_LABELS}`, () => {
    const labels = [
      { id: 1, title: 'scoped' },
      { id: 2, title: 'scoped::label::one', set: false },
      { id: 3, title: 'scoped::label::two', set: false },
      { id: 4, title: 'scoped::label::three', set: true },
      { id: 5, title: 'scoped::one', set: false },
      { id: 6, title: 'scoped::two', set: false },
      { id: 7, title: 'scoped::three', set: true },
      { id: 8, title: '' },
    ];

    it.each`
      label        | labelGroupIds
      ${labels[0]} | ${[]}
      ${labels[1]} | ${[labels[2], labels[3]]}
      ${labels[2]} | ${[labels[1], labels[3]]}
      ${labels[3]} | ${[labels[1], labels[2]]}
      ${labels[4]} | ${[labels[5], labels[6]]}
      ${labels[5]} | ${[labels[4], labels[6]]}
      ${labels[6]} | ${[labels[4], labels[5]]}
      ${labels[7]} | ${[]}
    `('updates `touched` and `set` props for $label.title', ({ label, labelGroupIds }) => {
      const state = { labels: cloneDeep(labels) };

      mutations[types.UPDATE_SELECTED_LABELS](state, { labels: [{ id: label.id }] });

      expect(state.labels[label.id - 1]).toMatchObject({
        touched: true,
        set: !labels[label.id - 1].set,
      });

      labelGroupIds.forEach((l) => {
        expect(state.labels[l.id - 1].touched).toBeUndefined();
        expect(state.labels[l.id - 1].set).toBe(false);
      });
    });
    it('allows selection of multiple scoped labels', () => {
      const state = { labels: cloneDeep(labels), allowMultipleScopedLabels: true };

      mutations[types.UPDATE_SELECTED_LABELS](state, { labels: [{ id: labels[4].id }] });
      mutations[types.UPDATE_SELECTED_LABELS](state, { labels: [{ id: labels[5].id }] });

      expect(state.labels[4].set).toBe(true);
      expect(state.labels[5].set).toBe(true);
      expect(state.labels[6].set).toBe(true);
    });
  });

  describe(`${types.UPDATE_LABELS_SET_STATE}`, () => {
    it('updates labels `set` state to match selected labels', () => {
      const state = {
        labels: [
          { id: 1, title: 'scoped::test', set: false, indeterminate: false },
          { id: 2, title: 'scoped::one', set: true, indeterminate: false, touched: true },
          { id: 3, title: '', set: false, indeterminate: false },
          { id: 4, title: '', set: false, indeterminate: false },
        ],
        selectedLabels: [
          { id: 1, set: true },
          { id: 3, set: true },
        ],
      };
      mutations[types.UPDATE_LABELS_SET_STATE](state);

      expect(state.labels).toEqual([
        { id: 1, title: 'scoped::test', set: true, indeterminate: false },
        { id: 2, title: 'scoped::one', set: false, indeterminate: false, touched: true },
        { id: 3, title: '', set: true, indeterminate: false },
        { id: 4, title: '', set: false, indeterminate: false },
      ]);
    });
  });
});
