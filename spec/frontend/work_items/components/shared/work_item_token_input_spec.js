import Vue from 'vue';
import { GlTokenSelector } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemTokenInput from '~/work_items/components/shared/work_item_token_input.vue';
import { WORK_ITEM_TYPE_ENUM_TASK } from '~/work_items/constants';
import groupWorkItemsQuery from '~/work_items/graphql/group_work_items.query.graphql';
import projectWorkItemsQuery from '~/work_items/graphql/project_work_items.query.graphql';
import { availableWorkItemsResponse, searchedWorkItemsResponse } from '../../mock_data';

Vue.use(VueApollo);

describe('WorkItemTokenInput', () => {
  let wrapper;

  const availableWorkItemsResolver = jest.fn().mockResolvedValue(availableWorkItemsResponse);
  const groupSearchedWorkItemResolver = jest.fn().mockResolvedValue(searchedWorkItemsResponse);
  const searchedWorkItemResolver = jest.fn().mockResolvedValue(searchedWorkItemsResponse);

  const createComponent = async ({
    workItemsToAdd = [],
    parentConfidential = false,
    childrenType = WORK_ITEM_TYPE_ENUM_TASK,
    areWorkItemsToAddValid = true,
    workItemsResolver = searchedWorkItemResolver,
    isGroup = false,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemTokenInput, {
      apolloProvider: createMockApollo([
        [projectWorkItemsQuery, workItemsResolver],
        [groupWorkItemsQuery, groupSearchedWorkItemResolver],
      ]),
      provide: {
        isGroup,
      },
      propsData: {
        value: workItemsToAdd,
        childrenType,
        childrenIds: [],
        fullPath: 'test-project-path',
        parentWorkItemId: 'gid://gitlab/WorkItem/1',
        parentConfidential,
        areWorkItemsToAddValid,
      },
    });

    await waitForPromises();
  };

  const findTokenSelector = () => wrapper.findComponent(GlTokenSelector);

  it('searches for available work items on focus', async () => {
    createComponent({ workItemsResolver: availableWorkItemsResolver });
    findTokenSelector().vm.$emit('focus');
    await waitForPromises();

    expect(availableWorkItemsResolver).toHaveBeenCalledWith({
      fullPath: 'test-project-path',
      searchTerm: '',
      types: [WORK_ITEM_TYPE_ENUM_TASK],
      in: undefined,
    });
    expect(findTokenSelector().props('dropdownItems')).toHaveLength(3);
  });

  it('searches for available work items when typing in input', async () => {
    createComponent({ workItemsResolver: searchedWorkItemResolver });
    findTokenSelector().vm.$emit('focus');
    findTokenSelector().vm.$emit('text-input', 'Task 2');
    await waitForPromises();

    expect(searchedWorkItemResolver).toHaveBeenCalledWith({
      fullPath: 'test-project-path',
      searchTerm: 'Task 2',
      types: [WORK_ITEM_TYPE_ENUM_TASK],
      in: 'TITLE',
    });
    expect(findTokenSelector().props('dropdownItems')).toHaveLength(1);
  });

  it('renders red border around token selector input when work item is not valid', () => {
    createComponent({
      areWorkItemsToAddValid: false,
    });

    expect(findTokenSelector().props('containerClass')).toBe('gl-inset-border-1-red-500!');
  });

  describe('when project context', () => {
    beforeEach(() => {
      createComponent();
      findTokenSelector().vm.$emit('focus');
    });

    it('calls the project work items query', () => {
      expect(searchedWorkItemResolver).toHaveBeenCalled();
    });

    it('skips calling the group work items query', () => {
      expect(groupSearchedWorkItemResolver).not.toHaveBeenCalled();
    });
  });

  describe('when group context', () => {
    beforeEach(() => {
      createComponent({ isGroup: true });
      findTokenSelector().vm.$emit('focus');
    });

    it('skips calling the project work items query', () => {
      expect(searchedWorkItemResolver).not.toHaveBeenCalled();
    });

    it('calls the group work items query', () => {
      expect(groupSearchedWorkItemResolver).toHaveBeenCalled();
    });
  });
});
