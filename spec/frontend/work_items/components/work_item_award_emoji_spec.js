import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { isLoggedIn } from '~/lib/utils/common_utils';
import AwardList from '~/vue_shared/components/awards_list.vue';
import WorkItemAwardEmoji from '~/work_items/components/work_item_award_emoji.vue';
import updateWorkItemMutation from '~/work_items/graphql/update_work_item.mutation.graphql';
import {
  EMOJI_ACTION_REMOVE,
  EMOJI_ACTION_ADD,
  EMOJI_THUMBSUP,
  EMOJI_THUMBSDOWN,
} from '~/work_items/constants';

import {
  workItemByIidResponseFactory,
  mockAwardsWidget,
  updateWorkItemMutationResponseFactory,
  mockAwardEmojiThumbsUp,
} from '../mock_data';

jest.mock('~/lib/utils/common_utils');
Vue.use(VueApollo);

describe('WorkItemAwardEmoji component', () => {
  let wrapper;

  const errorMessage = 'Failed to update the award';

  const workItemQueryResponse = workItemByIidResponseFactory();
  const workItemSuccessHandler = jest
    .fn()
    .mockResolvedValue(updateWorkItemMutationResponseFactory());
  const awardEmojiAddSuccessHandler = jest.fn().mockResolvedValue(
    updateWorkItemMutationResponseFactory({
      awardEmoji: {
        ...mockAwardsWidget,
        nodes: [mockAwardEmojiThumbsUp],
      },
    }),
  );
  const awardEmojiRemoveSuccessHandler = jest.fn().mockResolvedValue(
    updateWorkItemMutationResponseFactory({
      awardEmoji: {
        ...mockAwardsWidget,
        nodes: [],
      },
    }),
  );
  const workItemUpdateFailureHandler = jest.fn().mockRejectedValue(new Error(errorMessage));
  const mockWorkItem = workItemQueryResponse.data.workspace.workItems.nodes[0];

  const createComponent = ({
    mockWorkItemUpdateMutationHandler = [updateWorkItemMutation, workItemSuccessHandler],
    workItem = mockWorkItem,
    awardEmoji = { ...mockAwardsWidget, nodes: [] },
  } = {}) => {
    wrapper = shallowMount(WorkItemAwardEmoji, {
      isLoggedIn: isLoggedIn(),
      apolloProvider: createMockApollo([mockWorkItemUpdateMutationHandler]),
      propsData: {
        workItem,
        awardEmoji,
      },
    });
  };

  const findAwardsList = () => wrapper.findComponent(AwardList);

  beforeEach(() => {
    isLoggedIn.mockReturnValue(true);
    window.gon = {
      current_user_id: 1,
    };

    createComponent();
  });

  it('renders the award-list component with default props', () => {
    expect(findAwardsList().exists()).toBe(true);
    expect(findAwardsList().props()).toEqual({
      boundary: '',
      canAwardEmoji: true,
      currentUserId: 1,
      defaultAwards: [EMOJI_THUMBSUP, EMOJI_THUMBSDOWN],
      selectedClass: 'selected',
      awards: [],
    });
  });

  it('renders awards-list component with awards present', () => {
    createComponent({ awardEmoji: mockAwardsWidget });

    expect(findAwardsList().props('awards')).toEqual([
      {
        id: 1,
        name: EMOJI_THUMBSUP,
        user: {
          id: 5,
        },
      },
      {
        id: 2,
        name: EMOJI_THUMBSDOWN,
        user: {
          id: 5,
        },
      },
    ]);
  });

  it.each`
    expectedAssertion | action                 | successHandler                    | mockAwardEmojiNodes
    ${'added'}        | ${EMOJI_ACTION_ADD}    | ${awardEmojiAddSuccessHandler}    | ${[]}
    ${'removed'}      | ${EMOJI_ACTION_REMOVE} | ${awardEmojiRemoveSuccessHandler} | ${[mockAwardEmojiThumbsUp]}
  `(
    'calls mutation when an award emoji is $expectedAssertion',
    async ({ action, successHandler, mockAwardEmojiNodes }) => {
      createComponent({
        mockWorkItemUpdateMutationHandler: [updateWorkItemMutation, successHandler],
        awardEmoji: {
          ...mockAwardsWidget,
          nodes: mockAwardEmojiNodes,
        },
      });

      findAwardsList().vm.$emit('award', EMOJI_THUMBSUP);

      await waitForPromises();

      expect(successHandler).toHaveBeenCalledWith({
        input: {
          id: mockWorkItem.id,
          awardEmojiWidget: {
            action,
            name: EMOJI_THUMBSUP,
          },
        },
      });
    },
  );

  it('emits error when the update mutation fails', async () => {
    createComponent({
      mockWorkItemUpdateMutationHandler: [updateWorkItemMutation, workItemUpdateFailureHandler],
    });

    findAwardsList().vm.$emit('award', EMOJI_THUMBSUP);

    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([[errorMessage]]);
  });

  describe('when user is not logged in', () => {
    beforeEach(() => {
      isLoggedIn.mockReturnValue(false);

      createComponent();
    });

    it('renders the component with required props and canAwardEmoji false', () => {
      expect(findAwardsList().props('canAwardEmoji')).toBe(false);
    });
  });
});
