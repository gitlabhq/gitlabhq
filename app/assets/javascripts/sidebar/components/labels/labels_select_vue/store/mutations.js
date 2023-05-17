import { isScopedLabel, scopedLabelKey } from '~/lib/utils/common_utils';
import { VARIANT_SIDEBAR } from '~/sidebar/components/labels/labels_select_widget/constants';
import * as types from './mutation_types';

const transformLabels = (labels, selectedLabels) =>
  labels.map((label) => {
    const selectedLabel = selectedLabels.find(({ id }) => id === label.id);

    return {
      ...label,
      set: Boolean(selectedLabel?.set),
      indeterminate: Boolean(selectedLabel?.indeterminate),
    };
  });

export default {
  [types.SET_INITIAL_STATE](state, props) {
    // We need to ensure that selectedLabels have
    // `set` & `indeterminate` properties defined.
    if (props.selectedLabels?.length) {
      props.selectedLabels.forEach((label) => {
        /* eslint-disable no-param-reassign */
        if (label.set === undefined && label.indeterminate === undefined) {
          label.set = true;
          label.indeterminate = false;
        } else if (label.set === undefined && label.indeterminate !== undefined) {
          label.set = false;
        } else if (label.set !== undefined && label.indeterminate === undefined) {
          label.indeterminate = false;
        } else {
          label.set = false;
          label.indeterminate = false;
        }
        /* eslint-enable no-param-reassign */
      });
    }

    Object.assign(state, { ...props });
  },

  [types.TOGGLE_DROPDOWN_BUTTON](state) {
    state.showDropdownButton = !state.showDropdownButton;
  },

  [types.TOGGLE_DROPDOWN_CONTENTS](state) {
    if (state.variant === VARIANT_SIDEBAR) {
      state.showDropdownButton = !state.showDropdownButton;
    }
    state.showDropdownContents = !state.showDropdownContents;
    // Ensure that Create View is hidden by default
    // when dropdown contents are revealed.
    if (state.showDropdownContents) {
      state.showDropdownContentsCreateView = false;
    }
  },

  [types.TOGGLE_DROPDOWN_CONTENTS_CREATE_VIEW](state) {
    state.showDropdownContentsCreateView = !state.showDropdownContentsCreateView;
  },

  [types.REQUEST_LABELS](state) {
    state.labelsFetchInProgress = true;
  },
  [types.RECEIVE_SET_LABELS_SUCCESS](state, labels) {
    // Iterate over every label and add a `set` prop
    // to determine whether it is already a part of
    // selectedLabels array.
    state.labelsFetchInProgress = false;
    state.labelsFetched = true;
    state.labels = transformLabels(labels, state.selectedLabels);
  },
  [types.RECEIVE_SET_LABELS_FAILURE](state) {
    state.labelsFetchInProgress = false;
  },

  [types.REQUEST_CREATE_LABEL](state) {
    state.labelCreateInProgress = true;
  },
  [types.RECEIVE_CREATE_LABEL_SUCCESS](state) {
    state.labelCreateInProgress = false;
  },
  [types.RECEIVE_CREATE_LABEL_FAILURE](state) {
    state.labelCreateInProgress = false;
  },

  [types.UPDATE_SELECTED_LABELS](state, { labels }) {
    // Find the label to update from all the labels
    // and change `set` prop value to represent their current state.
    const labelId = labels.pop()?.id;
    const candidateLabel = state.labels.find((label) => labelId === label.id);
    if (candidateLabel) {
      candidateLabel.touched = true;
      candidateLabel.set = candidateLabel.indeterminate ? true : !candidateLabel.set;
      candidateLabel.indeterminate = false;
    }

    if (isScopedLabel(candidateLabel) && !state.allowMultipleScopedLabels) {
      const currentActiveScopedLabel = state.labels.find(
        ({ set, title }) =>
          set &&
          title !== candidateLabel.title &&
          scopedLabelKey({ title }) === scopedLabelKey(candidateLabel),
      );
      if (currentActiveScopedLabel) {
        currentActiveScopedLabel.set = false;
      }
    }
  },

  [types.UPDATE_LABELS_SET_STATE](state) {
    state.labels = transformLabels(state.labels, state.selectedLabels);
  },
};
