import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlForm, GlFormRadioGroup, GlAlert } from '@gitlab/ui';
import { s__ } from '~/locale';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import WorkItemAddRelationshipForm from '~/work_items/components/work_item_relationships/work_item_add_relationship_form.vue';
import WorkItemTokenInput from '~/work_items/components/shared/work_item_token_input.vue';
import addLinkedItemsMutation from '~/work_items/graphql/add_linked_items.mutation.graphql';
import { LINKED_ITEM_TYPE_VALUE } from '~/work_items/constants';

import { linkedWorkItemResponse } from '../../mock_data';

describe('WorkItemAddRelationshipForm', () => {
  Vue.use(VueApollo);

  let wrapper;
  const linkedWorkItemsSuccessMutationHandler = jest
    .fn()
    .mockResolvedValue(linkedWorkItemResponse());

  const createComponent = async ({
    workItemId = 'gid://gitlab/WorkItem/1',
    workItemIid = '1',
    workItemType = 'Objective',
    childrenIds = [],
    linkedWorkItemsMutationHandler = linkedWorkItemsSuccessMutationHandler,
  } = {}) => {
    const mockApolloProvider = createMockApollo([
      [addLinkedItemsMutation, linkedWorkItemsMutationHandler],
    ]);

    wrapper = shallowMountExtended(WorkItemAddRelationshipForm, {
      apolloProvider: mockApolloProvider,
      propsData: {
        workItemId,
        workItemIid,
        workItemFullPath: 'test-project-path',
        workItemType,
        childrenIds,
      },
    });

    await waitForPromises();
  };

  const findLinkWorkItemForm = () => wrapper.findComponent(GlForm);
  const findLinkWorkItemButton = () => wrapper.findByTestId('link-work-item-button');
  const findMaxWorkItemNote = () => wrapper.findByTestId('max-work-item-note');
  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findWorkItemTokenInput = () => wrapper.findComponent(WorkItemTokenInput);
  const findGlAlert = () => wrapper.findComponent(GlAlert);

  beforeEach(async () => {
    await createComponent();
  });

  it('renders link work item form with default values', () => {
    expect(findLinkWorkItemForm().exists()).toBe(true);
    expect(findRadioGroup().props('options')).toEqual([
      { text: s__('WorkItem|relates to'), value: LINKED_ITEM_TYPE_VALUE.RELATED },
      { text: s__('WorkItem|blocks'), value: LINKED_ITEM_TYPE_VALUE.BLOCKS },
      { text: s__('WorkItem|is blocked by'), value: LINKED_ITEM_TYPE_VALUE.BLOCKED_BY },
    ]);
    expect(findLinkWorkItemButton().attributes('disabled')).toBe('true');
    expect(findMaxWorkItemNote().text()).toBe(s__('WorkItem|Add a maximum of 3 items at a time.'));
  });

  it('renders work item token input with default props', () => {
    expect(findWorkItemTokenInput().props()).toMatchObject({
      value: [],
      fullPath: 'test-project-path',
      childrenIds: [],
      parentWorkItemId: 'gid://gitlab/WorkItem/1',
      areWorkItemsToAddValid: true,
    });
  });

  describe('linking a work item', () => {
    const selectWorkItemTokens = (workItems) => {
      findWorkItemTokenInput().vm.$emit('input', workItems);
    };

    it('enables add button when work item is selected', async () => {
      await selectWorkItemTokens([
        {
          id: 'gid://gitlab/WorkItem/644',
        },
      ]);
      expect(findLinkWorkItemButton().attributes('disabled')).toBeUndefined();
    });

    it('disables button when more than 3 work items are selected', async () => {
      await selectWorkItemTokens([
        {
          id: 'gid://gitlab/WorkItem/641',
        },
        {
          id: 'gid://gitlab/WorkItem/642',
        },
        {
          id: 'gid://gitlab/WorkItem/643',
        },
        {
          id: 'gid://gitlab/WorkItem/644',
        },
      ]);

      expect(findWorkItemTokenInput().props('areWorkItemsToAddValid')).toBe(false);
      expect(findLinkWorkItemButton().attributes('disabled')).toBe('true');
    });

    it.each`
      assertionName | linkTypeInput
      ${'related'}  | ${LINKED_ITEM_TYPE_VALUE.RELATED}
      ${'blocking'} | ${LINKED_ITEM_TYPE_VALUE.BLOCKED_BY}
    `('selects and links $assertionName work item', async ({ linkTypeInput }) => {
      findRadioGroup().vm.$emit('input', linkTypeInput);
      await selectWorkItemTokens([
        {
          id: 'gid://gitlab/WorkItem/641',
        },
        {
          id: 'gid://gitlab/WorkItem/642',
        },
      ]);

      expect(findWorkItemTokenInput().props('areWorkItemsToAddValid')).toBe(true);

      findLinkWorkItemForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
        stopPropagation: jest.fn(),
      });
      await waitForPromises();

      expect(linkedWorkItemsSuccessMutationHandler).toHaveBeenCalledWith({
        input: {
          id: 'gid://gitlab/WorkItem/1',
          linkType: linkTypeInput,
          workItemsIds: ['gid://gitlab/WorkItem/641', 'gid://gitlab/WorkItem/642'],
        },
      });
    });

    it.each`
      errorType                              | mutationMock                                                                       | errorMessage
      ${'an error in the mutation response'} | ${jest.fn().mockResolvedValue(linkedWorkItemResponse({}, ['Linked Item failed']))} | ${'Linked Item failed'}
      ${'a network error'}                   | ${jest.fn().mockRejectedValue(new Error('Network Error'))}                         | ${'Something went wrong when trying to link a item. Please try again.'}
    `('shows an error message when there is $errorType', async ({ mutationMock, errorMessage }) => {
      createComponent({ linkedWorkItemsMutationHandler: mutationMock });
      await selectWorkItemTokens([
        {
          id: 'gid://gitlab/WorkItem/641',
        },
      ]);

      findLinkWorkItemForm().vm.$emit('submit', {
        preventDefault: jest.fn(),
        stopPropagation: jest.fn(),
      });
      await waitForPromises();

      expect(findGlAlert().exists()).toBe(true);
      expect(findGlAlert().text()).toBe(errorMessage);
    });
  });
});
