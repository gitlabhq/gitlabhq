import { get } from 'lodash';
import { mockBranches } from 'jest/vue_shared/components/filtered_search_bar/mock_data';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import * as types from '~/vue_shared/components/filtered_search_bar/store/modules/filters/mutation_types';
import mutations from '~/vue_shared/components/filtered_search_bar/store/modules/filters/mutations';
import initialState from '~/vue_shared/components/filtered_search_bar/store/modules/filters/state';
import { filterMilestones, filterUsers, filterLabels } from './mock_data';

let state = null;

const branches = mockBranches.map(convertObjectPropsToCamelCase);
const milestones = filterMilestones.map(convertObjectPropsToCamelCase);
const users = filterUsers.map(convertObjectPropsToCamelCase);
const labels = filterLabels.map(convertObjectPropsToCamelCase);

const filterValue = { value: 'foo' };

describe('Filters mutations', () => {
  beforeEach(() => {
    state = initialState();
  });

  afterEach(() => {
    state = null;
  });

  it.each`
    mutation                         | stateKey                | value
    ${types.SET_MILESTONES_ENDPOINT} | ${'milestonesEndpoint'} | ${'new-milestone-endpoint'}
    ${types.SET_LABELS_ENDPOINT}     | ${'labelsEndpoint'}     | ${'new-label-endpoint'}
    ${types.SET_GROUP_ENDPOINT}      | ${'groupEndpoint'}      | ${'new-group-endpoint'}
  `('$mutation will set $stateKey=$value', ({ mutation, stateKey, value }) => {
    mutations[mutation](state, value);

    expect(state[stateKey]).toEqual(value);
  });

  it.each`
    mutation                      | stateKey                          | filterName                    | value
    ${types.SET_SELECTED_FILTERS} | ${'branches.source.selected'}     | ${'selectedSourceBranch'}     | ${null}
    ${types.SET_SELECTED_FILTERS} | ${'branches.source.selected'}     | ${'selectedSourceBranch'}     | ${filterValue}
    ${types.SET_SELECTED_FILTERS} | ${'branches.source.selectedList'} | ${'selectedSourceBranchList'} | ${[]}
    ${types.SET_SELECTED_FILTERS} | ${'branches.source.selectedList'} | ${'selectedSourceBranchList'} | ${[filterValue]}
    ${types.SET_SELECTED_FILTERS} | ${'branches.target.selected'}     | ${'selectedTargetBranch'}     | ${null}
    ${types.SET_SELECTED_FILTERS} | ${'branches.target.selected'}     | ${'selectedTargetBranch'}     | ${filterValue}
    ${types.SET_SELECTED_FILTERS} | ${'branches.target.selectedList'} | ${'selectedTargetBranchList'} | ${[]}
    ${types.SET_SELECTED_FILTERS} | ${'branches.target.selectedList'} | ${'selectedTargetBranchList'} | ${[filterValue]}
    ${types.SET_SELECTED_FILTERS} | ${'authors.selected'}             | ${'selectedAuthor'}           | ${null}
    ${types.SET_SELECTED_FILTERS} | ${'authors.selected'}             | ${'selectedAuthor'}           | ${filterValue}
    ${types.SET_SELECTED_FILTERS} | ${'authors.selectedList'}         | ${'selectedAuthorList'}       | ${[]}
    ${types.SET_SELECTED_FILTERS} | ${'authors.selectedList'}         | ${'selectedAuthorList'}       | ${[filterValue]}
    ${types.SET_SELECTED_FILTERS} | ${'milestones.selected'}          | ${'selectedMilestone'}        | ${null}
    ${types.SET_SELECTED_FILTERS} | ${'milestones.selected'}          | ${'selectedMilestone'}        | ${filterValue}
    ${types.SET_SELECTED_FILTERS} | ${'milestones.selectedList'}      | ${'selectedMilestoneList'}    | ${[]}
    ${types.SET_SELECTED_FILTERS} | ${'milestones.selectedList'}      | ${'selectedMilestoneList'}    | ${[filterValue]}
    ${types.SET_SELECTED_FILTERS} | ${'assignees.selected'}           | ${'selectedAssignee'}         | ${null}
    ${types.SET_SELECTED_FILTERS} | ${'assignees.selected'}           | ${'selectedAssignee'}         | ${filterValue}
    ${types.SET_SELECTED_FILTERS} | ${'assignees.selectedList'}       | ${'selectedAssigneeList'}     | ${[]}
    ${types.SET_SELECTED_FILTERS} | ${'assignees.selectedList'}       | ${'selectedAssigneeList'}     | ${[filterValue]}
    ${types.SET_SELECTED_FILTERS} | ${'labels.selected'}              | ${'selectedLabel'}            | ${null}
    ${types.SET_SELECTED_FILTERS} | ${'labels.selected'}              | ${'selectedLabel'}            | ${filterValue}
    ${types.SET_SELECTED_FILTERS} | ${'labels.selectedList'}          | ${'selectedLabelList'}        | ${[]}
    ${types.SET_SELECTED_FILTERS} | ${'labels.selectedList'}          | ${'selectedLabelList'}        | ${[filterValue]}
  `(
    '$mutation will set $stateKey with a given value',
    ({ mutation, stateKey, filterName, value }) => {
      mutations[mutation](state, { [filterName]: value });

      expect(get(state, stateKey)).toEqual(value);
    },
  );

  it.each`
    mutation                            | rootKey         | stateKey       | value
    ${types.REQUEST_BRANCHES}           | ${'branches'}   | ${'isLoading'} | ${true}
    ${types.RECEIVE_BRANCHES_SUCCESS}   | ${'branches'}   | ${'isLoading'} | ${false}
    ${types.RECEIVE_BRANCHES_SUCCESS}   | ${'branches'}   | ${'data'}      | ${branches}
    ${types.RECEIVE_BRANCHES_SUCCESS}   | ${'branches'}   | ${'errorCode'} | ${null}
    ${types.RECEIVE_BRANCHES_ERROR}     | ${'branches'}   | ${'isLoading'} | ${false}
    ${types.RECEIVE_BRANCHES_ERROR}     | ${'branches'}   | ${'data'}      | ${[]}
    ${types.RECEIVE_BRANCHES_ERROR}     | ${'branches'}   | ${'errorCode'} | ${HTTP_STATUS_INTERNAL_SERVER_ERROR}
    ${types.REQUEST_MILESTONES}         | ${'milestones'} | ${'isLoading'} | ${true}
    ${types.RECEIVE_MILESTONES_SUCCESS} | ${'milestones'} | ${'isLoading'} | ${false}
    ${types.RECEIVE_MILESTONES_SUCCESS} | ${'milestones'} | ${'data'}      | ${milestones}
    ${types.RECEIVE_MILESTONES_SUCCESS} | ${'milestones'} | ${'errorCode'} | ${null}
    ${types.RECEIVE_MILESTONES_ERROR}   | ${'milestones'} | ${'isLoading'} | ${false}
    ${types.RECEIVE_MILESTONES_ERROR}   | ${'milestones'} | ${'data'}      | ${[]}
    ${types.RECEIVE_MILESTONES_ERROR}   | ${'milestones'} | ${'errorCode'} | ${HTTP_STATUS_INTERNAL_SERVER_ERROR}
    ${types.REQUEST_AUTHORS}            | ${'authors'}    | ${'isLoading'} | ${true}
    ${types.RECEIVE_AUTHORS_SUCCESS}    | ${'authors'}    | ${'isLoading'} | ${false}
    ${types.RECEIVE_AUTHORS_SUCCESS}    | ${'authors'}    | ${'data'}      | ${users}
    ${types.RECEIVE_AUTHORS_SUCCESS}    | ${'authors'}    | ${'errorCode'} | ${null}
    ${types.RECEIVE_AUTHORS_ERROR}      | ${'authors'}    | ${'isLoading'} | ${false}
    ${types.RECEIVE_AUTHORS_ERROR}      | ${'authors'}    | ${'data'}      | ${[]}
    ${types.RECEIVE_AUTHORS_ERROR}      | ${'authors'}    | ${'errorCode'} | ${HTTP_STATUS_INTERNAL_SERVER_ERROR}
    ${types.REQUEST_LABELS}             | ${'labels'}     | ${'isLoading'} | ${true}
    ${types.RECEIVE_LABELS_SUCCESS}     | ${'labels'}     | ${'isLoading'} | ${false}
    ${types.RECEIVE_LABELS_SUCCESS}     | ${'labels'}     | ${'data'}      | ${labels}
    ${types.RECEIVE_LABELS_SUCCESS}     | ${'labels'}     | ${'errorCode'} | ${null}
    ${types.RECEIVE_LABELS_ERROR}       | ${'labels'}     | ${'isLoading'} | ${false}
    ${types.RECEIVE_LABELS_ERROR}       | ${'labels'}     | ${'data'}      | ${[]}
    ${types.RECEIVE_LABELS_ERROR}       | ${'labels'}     | ${'errorCode'} | ${HTTP_STATUS_INTERNAL_SERVER_ERROR}
    ${types.REQUEST_ASSIGNEES}          | ${'assignees'}  | ${'isLoading'} | ${true}
    ${types.RECEIVE_ASSIGNEES_SUCCESS}  | ${'assignees'}  | ${'isLoading'} | ${false}
    ${types.RECEIVE_ASSIGNEES_SUCCESS}  | ${'assignees'}  | ${'data'}      | ${users}
    ${types.RECEIVE_ASSIGNEES_SUCCESS}  | ${'assignees'}  | ${'errorCode'} | ${null}
    ${types.RECEIVE_ASSIGNEES_ERROR}    | ${'assignees'}  | ${'isLoading'} | ${false}
    ${types.RECEIVE_ASSIGNEES_ERROR}    | ${'assignees'}  | ${'data'}      | ${[]}
    ${types.RECEIVE_ASSIGNEES_ERROR}    | ${'assignees'}  | ${'errorCode'} | ${HTTP_STATUS_INTERNAL_SERVER_ERROR}
  `('$mutation will set $stateKey with a given value', ({ mutation, rootKey, stateKey, value }) => {
    mutations[mutation](state, value);

    expect(state[rootKey][stateKey]).toEqual(value);
  });
});
