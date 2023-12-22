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
import workItemsByReferencesQuery from '~/work_items/graphql/work_items_by_references.query.graphql';
import { searchWorkItemsResponse } from '../../mock_data';

Vue.use(VueApollo);

describe('WorkItemTokenInput', () => {
  let wrapper;

  const availableWorkItemsResolver = jest.fn().mockResolvedValue(
    searchWorkItemsResponse({
      workItems: [
        {
          id: 'gid://gitlab/WorkItem/458',
          iid: '2',
          title: 'Task 1',
          confidential: false,
          __typename: 'WorkItem',
        },
        {
          id: 'gid://gitlab/WorkItem/459',
          iid: '3',
          title: 'Task 2',
          confidential: false,
          __typename: 'WorkItem',
        },
        {
          id: 'gid://gitlab/WorkItem/460',
          iid: '4',
          title: 'Task 3',
          confidential: false,
          __typename: 'WorkItem',
        },
      ],
    }),
  );

  const mockWorkItem = {
    id: 'gid://gitlab/WorkItem/459',
    iid: '3',
    title: 'Task 2',
    confidential: false,
    __typename: 'WorkItem',
  };
  const groupSearchedWorkItemResolver = jest.fn().mockResolvedValue(
    searchWorkItemsResponse({
      workItems: [mockWorkItem],
    }),
  );
  const searchWorkItemTextResolver = jest.fn().mockResolvedValue(
    searchWorkItemsResponse({
      workItems: [mockWorkItem],
    }),
  );
  const mockworkItemReferenceQueryResponse = {
    data: {
      workItemsByReference: {
        nodes: [
          {
            id: 'gid://gitlab/WorkItem/705',
            iid: '111',
            title: 'Objective linked items 104',
            confidential: false,
            __typename: 'WorkItem',
          },
        ],
        __typename: 'WorkItemConnection',
      },
    },
  };
  const workItemReferencesQueryResolver = jest
    .fn()
    .mockResolvedValue(mockworkItemReferenceQueryResponse);

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
        [workItemsByReferencesQuery, workItemReferencesQueryResolver],
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
  const findNoMatchFoundMessage = () => wrapper.findByTestId('no-match-found-namespace-message');

  it('searches for available work items on focus', async () => {
    createComponent({ workItemsResolver: availableWorkItemsResolver });
    findTokenSelector().vm.$emit('focus');
    await waitForPromises();

    expect(availableWorkItemsResolver).toHaveBeenCalledWith({
      fullPath: 'test-project-path',
      searchTerm: '',
      types: [WORK_ITEM_TYPE_ENUM_TASK],
      iid: null,
      searchByIid: false,
      searchByText: true,
    });
    expect(findTokenSelector().props('dropdownItems')).toHaveLength(3);
  });

  it('renders red border around token selector input when work item is not valid', () => {
    createComponent({
      areWorkItemsToAddValid: false,
    });

    expect(findTokenSelector().props('containerClass')).toBe('gl-inset-border-1-red-500!');
  });

  describe('when input data is provided', () => {
    const fillWorkItemInput = (input) => {
      findTokenSelector().vm.$emit('focus');
      findTokenSelector().vm.$emit('text-input', input);
    };

    const mockWorkItemResponseItem1 = {
      id: 'gid://gitlab/WorkItem/460',
      iid: '101',
      title: 'Task 3',
      confidential: false,
      __typename: 'WorkItem',
    };
    const mockWorkItemResponseItem2 = {
      id: 'gid://gitlab/WorkItem/461',
      iid: '3',
      title: 'Task 123',
      confidential: false,
      __typename: 'WorkItem',
    };
    const mockWorkItemResponseItem3 = {
      id: 'gid://gitlab/WorkItem/462',
      iid: '123',
      title: 'Task 2',
      confidential: false,
      __typename: 'WorkItem',
    };

    const searchWorkItemIidResolver = jest.fn().mockResolvedValue(
      searchWorkItemsResponse({
        workItemsByIid: [mockWorkItemResponseItem1],
      }),
    );
    const searchWorkItemTextIidResolver = jest.fn().mockResolvedValue(
      searchWorkItemsResponse({
        workItems: [mockWorkItemResponseItem2],
        workItemsByIid: [mockWorkItemResponseItem3],
      }),
    );

    const emptyWorkItemResolver = jest.fn().mockResolvedValue(searchWorkItemsResponse());

    const validIid = mockWorkItemResponseItem1.iid;
    const validWildCardIid = `#${mockWorkItemResponseItem1.iid}`;
    const searchedText = mockWorkItem.title;
    const searchedIidText = mockWorkItemResponseItem3.iid;
    const nonExistentIid = '111';
    const nonExistentWorkItem = 'Key result';
    const validWorkItemUrl = 'http://localhost/gitlab-org/test-project-path/-/work_items/111';
    const validWorkItemReference = 'gitlab-org/test-project-path#111';
    const invalidWorkItemUrl = 'invalid-url/gitlab-org/test-project-path/-/work_items/101';

    it.each`
      inputType         | input              | resolver                         | searchTerm         | iid                | searchByText | searchByIid | length
      ${'iid'}          | ${validIid}        | ${searchWorkItemIidResolver}     | ${validIid}        | ${validIid}        | ${true}      | ${true}     | ${1}
      ${'text'}         | ${searchedText}    | ${searchWorkItemTextResolver}    | ${searchedText}    | ${null}            | ${true}      | ${false}    | ${1}
      ${'iid and text'} | ${searchedIidText} | ${searchWorkItemTextIidResolver} | ${searchedIidText} | ${searchedIidText} | ${true}      | ${true}     | ${2}
    `(
      'lists work items when $inputType is valid',
      async ({ input, resolver, searchTerm, iid, searchByIid, searchByText, length }) => {
        createComponent({ workItemsResolver: resolver });

        fillWorkItemInput(input);

        await waitForPromises();

        expect(resolver).toHaveBeenCalledWith({
          fullPath: 'test-project-path',
          types: [WORK_ITEM_TYPE_ENUM_TASK],
          searchTerm,
          in: 'TITLE',
          iid,
          searchByIid,
          searchByText,
        });
        expect(findTokenSelector().props('dropdownItems')).toHaveLength(length);
      },
    );

    it.each`
      inputType | input                  | searchTerm             | iid               | searchByText | searchByIid
      ${'iid'}  | ${nonExistentIid}      | ${nonExistentIid}      | ${nonExistentIid} | ${true}      | ${true}
      ${'text'} | ${nonExistentWorkItem} | ${nonExistentWorkItem} | ${null}           | ${true}      | ${false}
      ${'url'}  | ${invalidWorkItemUrl}  | ${invalidWorkItemUrl}  | ${null}           | ${true}      | ${false}
    `(
      'list is empty when $inputType is invalid',
      async ({ input, searchTerm, iid, searchByIid, searchByText }) => {
        createComponent({ workItemsResolver: emptyWorkItemResolver });

        fillWorkItemInput(input);

        await waitForPromises();

        expect(emptyWorkItemResolver).toHaveBeenCalledWith({
          fullPath: 'test-project-path',
          types: [WORK_ITEM_TYPE_ENUM_TASK],
          searchTerm,
          in: 'TITLE',
          iid,
          searchByIid,
          searchByText,
        });
        expect(findTokenSelector().props('dropdownItems')).toHaveLength(0);
      },
    );

    it.each`
      inputType              | input                     | refs                        | length
      ${'iid with wildcard'} | ${validWildCardIid}       | ${[validWildCardIid]}       | ${1}
      ${'url'}               | ${validWorkItemUrl}       | ${[validWorkItemUrl]}       | ${1}
      ${'reference'}         | ${validWorkItemReference} | ${[validWorkItemReference]} | ${1}
    `('lists work items when valid $inputType is pasted', async ({ input, refs, length }) => {
      createComponent({ workItemsResolver: workItemReferencesQueryResolver });

      fillWorkItemInput(input);

      await waitForPromises();

      expect(workItemReferencesQueryResolver).toHaveBeenCalledWith({
        contextNamespacePath: 'test-project-path',
        refs,
      });
      expect(findTokenSelector().props('dropdownItems')).toHaveLength(length);
    });

    it('shows proper message if provided with cross project URL', async () => {
      createComponent({ workItemsResolver: emptyWorkItemResolver });

      fillWorkItemInput('http://localhost/gitlab-org/cross-project-path/-/work_items/101');

      await waitForPromises();

      expect(findNoMatchFoundMessage().text()).toBe('No matches found');
    });
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
