import { isScopedLabel, scopedLabelKey } from '~/lib/utils/common_utils';
import { DropdownVariant } from '../constants';
import * as types from './mutation_types';

export default {
  [types.SET_INITIAL_STATE](state, props) {
    Object.assign(state, { ...props });
  },

  [types.TOGGLE_DROPDOWN_BUTTON](state) {
    state.showDropdownButton = !state.showDropdownButton;
  },

  [types.TOGGLE_DROPDOWN_CONTENTS](state) {
    if (state.variant === DropdownVariant.Sidebar) {
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
    const selectedLabelIds = state.selectedLabels.map((label) => label.id);
    state.labelsFetchInProgress = false;
    state.labelsFetched = true;
    state.labels = labels.reduce((allLabels, label) => {
      allLabels.push({
        ...label,
        set: selectedLabelIds.includes(label.id),
      });
      return allLabels;
    }, []);
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
      candidateLabel.set = !candidateLabel.set;
    }

    if (isScopedLabel(candidateLabel)) {
      const scopedBase = scopedLabelKey(candidateLabel);
      const currentActiveScopedLabel = state.labels.find(({ title }) => {
        return title.startsWith(scopedBase) && title !== '' && title !== candidateLabel.title;
      });

      if (currentActiveScopedLabel) {
        currentActiveScopedLabel.set = false;
      }
    }
  },
};
