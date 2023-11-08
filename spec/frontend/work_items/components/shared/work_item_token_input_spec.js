import Vue, { nextTick } from 'vue';
import { GlTokenSelector, GlAlert } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemTokenInput from '~/work_items/components/shared/work_item_token_input.vue';
import { WORK_ITEM_TYPE_ENUM_TASK } from '~/work_items/constants';
import groupWorkItemsQuery from '~/work_items/graphql/group_work_items.query.graphql';
import projectWorkItemsQuery from '~/work_items/graphql/project_work_items.query.graphql';
import {
  availableWorkItemsResponse,
  searchWorkItemsTextResponse,
  searchWorkItemsIidResponse,
  searchWorkItemsTextIidResponse,
} from '../../mock_data';

Vue.use(VueApollo);

describe('WorkItemTokenInput', () => {
  let wrapper;

  const availableWorkItemsResolver = jest.fn().mockResolvedValue(availableWorkItemsResponse);
  const groupSearchedWorkItemResolver = jest.fn().mockResolvedValue(searchWorkItemsTextResponse);
  const searchWorkItemTextResolver = jest.fn().mockResolvedValue(searchWorkItemsTextResponse);
  const searchWorkItemIidResolver = jest.fn().mockResolvedValue(searchWorkItemsIidResponse);
  const searchWorkItemTextIidResolver = jest.fn().mockResolvedValue(searchWorkItemsTextIidResponse);

  const createComponent = async ({
    workItemsToAdd = [],
    parentConfidential = false,
    childrenType = WORK_ITEM_TYPE_ENUM_TASK,
    areWorkItemsToAddValid = true,
    workItemsResolver = searchWorkItemTextResolver,
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
  const findGlAlert = () => wrapper.findComponent(GlAlert);

  it('searches for available work items on focus', async () => {
    createComponent({ workItemsResolver: availableWorkItemsResolver });
    findTokenSelector().vm.$emit('focus');
    await waitForPromises();

    expect(availableWorkItemsResolver).toHaveBeenCalledWith({
      fullPath: 'test-project-path',
      searchTerm: '',
      types: [WORK_ITEM_TYPE_ENUM_TASK],
      in: undefined,
      iid: null,
      isNumber: false,
    });
    expect(findTokenSelector().props('dropdownItems')).toHaveLength(3);
  });

  it.each`
    inputType         | input       | resolver                         | searchTerm  | iid      | isNumber | length
    ${'iid'}          | ${'101'}    | ${searchWorkItemIidResolver}     | ${'101'}    | ${'101'} | ${true}  | ${1}
    ${'text'}         | ${'Task 2'} | ${searchWorkItemTextResolver}    | ${'Task 2'} | ${null}  | ${false} | ${1}
    ${'iid and text'} | ${'123'}    | ${searchWorkItemTextIidResolver} | ${'123'}    | ${'123'} | ${true}  | ${2}
  `(
    'searches by $inputType for available work items when typing in input',
    async ({ input, resolver, searchTerm, iid, isNumber, length }) => {
      createComponent({ workItemsResolver: resolver });
      findTokenSelector().vm.$emit('focus');
      findTokenSelector().vm.$emit('text-input', input);
      await waitForPromises();

      expect(resolver).toHaveBeenCalledWith({
        searchTerm,
        in: 'TITLE',
        iid,
        isNumber,
      });
      expect(findTokenSelector().props('dropdownItems')).toHaveLength(length);
    },
  );

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
      expect(searchWorkItemTextResolver).toHaveBeenCalled();
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
      expect(searchWorkItemTextResolver).not.toHaveBeenCalled();
    });

    it('calls the group work items query', () => {
      expect(groupSearchedWorkItemResolver).toHaveBeenCalled();
    });
  });

  describe('when project work items query fails', () => {
    beforeEach(() => {
      createComponent({
        workItemsResolver: jest
          .fn()
          .mockRejectedValue('Something went wrong while fetching the results'),
      });
      findTokenSelector().vm.$emit('focus');
    });

    it('shows error and allows error alert to be closed', async () => {
      await waitForPromises();
      expect(findGlAlert().exists()).toBe(true);
      expect(findGlAlert().text()).toBe(
        'Something went wrong while fetching the task. Please try again.',
      );

      findGlAlert().vm.$emit('dismiss');
      await nextTick();

      expect(findGlAlert().exists()).toBe(false);
    });
  });
});
