import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { isLoggedIn } from '~/lib/utils/common_utils';
import AwardList from '~/vue_shared/components/awards_list.vue';
import WorkItemAwardEmoji from '~/work_items/components/work_item_award_emoji.vue';
import updateAwardEmojiMutation from '~/work_items/graphql/update_award_emoji.mutation.graphql';
import workItemByIidQuery from '~/work_items/graphql/work_item_by_iid.query.graphql';
import { EMOJI_THUMBSUP, EMOJI_THUMBSDOWN } from '~/work_items/constants';

import {
  workItemByIidResponseFactory,
  mockAwardsWidget,
  mockAwardEmojiThumbsUp,
  getAwardEmojiResponse,
} from '../mock_data';

jest.mock('~/lib/utils/common_utils');
Vue.use(VueApollo);

describe('WorkItemAwardEmoji component', () => {
  let wrapper;
  let mockApolloProvider;

  const errorMessage = 'Failed to update the award';
  const workItemQueryResponse = workItemByIidResponseFactory();
  const workItemQueryAddAwardEmojiResponse = workItemByIidResponseFactory({
    awardEmoji: { ...mockAwardsWidget, nodes: [mockAwardEmojiThumbsUp] },
  });
  const workItemQueryRemoveAwardEmojiResponse = workItemByIidResponseFactory({
    awardEmoji: { ...mockAwardsWidget, nodes: [] },
  });
  const awardEmojiAddSuccessHandler = jest.fn().mockResolvedValue(getAwardEmojiResponse(true));
  const awardEmojiRemoveSuccessHandler = jest.fn().mockResolvedValue(getAwardEmojiResponse(false));
  const awardEmojiUpdateFailureHandler = jest.fn().mockRejectedValue(new Error(errorMessage));
  const mockWorkItem = workItemQueryResponse.data.workspace.workItems.nodes[0];
  const mockAwardEmojiDifferentUserThumbsUp = {
    name: 'thumbsup',
    __typename: 'AwardEmoji',
    user: {
      id: 'gid://gitlab/User/1',
      name: 'John Doe',
      __typename: 'UserCore',
    },
  };

  const createComponent = ({
    awardMutationHandler = awardEmojiAddSuccessHandler,
    workItem = mockWorkItem,
    workItemIid = '1',
    awardEmoji = { ...mockAwardsWidget, nodes: [] },
  } = {}) => {
    mockApolloProvider = createMockApollo([[updateAwardEmojiMutation, awardMutationHandler]]);

    mockApolloProvider.clients.defaultClient.writeQuery({
      query: workItemByIidQuery,
      variables: { fullPath: workItem.project.fullPath, iid: workItemIid },
      data: {
        ...workItemQueryResponse.data,
        workspace: {
          __typename: 'Project',
          id: 'gid://gitlab/Project/1',
          workItems: {
            nodes: [workItem],
          },
        },
      },
    });

    wrapper = shallowMount(WorkItemAwardEmoji, {
      isLoggedIn: isLoggedIn(),
      apolloProvider: mockApolloProvider,
      propsData: {
        workItemId: workItem.id,
        workItemFullpath: workItem.project.fullPath,
        awardEmoji,
        workItemIid,
      },
    });
  };

  const findAwardsList = () => wrapper.findComponent(AwardList);

  beforeEach(() => {
    isLoggedIn.mockReturnValue(true);
    window.gon = {
      current_user_id: 5,
      current_user_fullname: 'Dave Smith',
    };

    createComponent();
  });

  it('renders the award-list component with default props', () => {
    expect(findAwardsList().exists()).toBe(true);
    expect(findAwardsList().props()).toEqual({
      boundary: '',
      canAwardEmoji: true,
      currentUserId: 5,
      defaultAwards: [EMOJI_THUMBSUP, EMOJI_THUMBSDOWN],
      selectedClass: 'selected',
      awards: [],
    });
  });

  it('renders awards-list component with awards present', () => {
    createComponent({ awardEmoji: mockAwardsWidget });

    expect(findAwardsList().props('awards')).toEqual([
      {
        name: EMOJI_THUMBSUP,
        user: {
          id: 5,
          name: 'Dave Smith',
        },
      },
      {
        name: EMOJI_THUMBSDOWN,
        user: {
          id: 5,
          name: 'Dave Smith',
        },
      },
    ]);
  });

  it('renders awards list given by multiple users', () => {
    createComponent({
      awardEmoji: {
        ...mockAwardsWidget,
        nodes: [mockAwardEmojiThumbsUp, mockAwardEmojiDifferentUserThumbsUp],
      },
    });

    expect(findAwardsList().props('awards')).toEqual([
      {
        name: EMOJI_THUMBSUP,
        user: {
          id: 5,
          name: 'Dave Smith',
        },
      },
      {
        name: EMOJI_THUMBSUP,
        user: {
          id: 1,
          name: 'John Doe',
        },
      },
    ]);
  });

  it.each`
    expectedAssertion | awardEmojiMutationHandler         | mockAwardEmojiNodes         | workItem
    ${'added'}        | ${awardEmojiAddSuccessHandler}    | ${[]}                       | ${workItemQueryRemoveAwardEmojiResponse.data.workspace.workItems.nodes[0]}
    ${'removed'}      | ${awardEmojiRemoveSuccessHandler} | ${[mockAwardEmojiThumbsUp]} | ${workItemQueryAddAwardEmojiResponse.data.workspace.workItems.nodes[0]}
  `(
    'calls mutation when an award emoji is $expectedAssertion',
    ({ awardEmojiMutationHandler, mockAwardEmojiNodes, workItem }) => {
      createComponent({
        awardMutationHandler: awardEmojiMutationHandler,
        awardEmoji: {
          ...mockAwardsWidget,
          nodes: mockAwardEmojiNodes,
        },
        workItem,
      });

      findAwardsList().vm.$emit('award', EMOJI_THUMBSUP);

      expect(awardEmojiMutationHandler).toHaveBeenCalledWith({
        input: {
          awardableId: mockWorkItem.id,
          name: EMOJI_THUMBSUP,
        },
      });
    },
  );

  it('emits error when the update mutation fails', async () => {
    createComponent({
      awardMutationHandler: awardEmojiUpdateFailureHandler,
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

  describe('when a different users awards same emoji', () => {
    beforeEach(() => {
      window.gon = {
        current_user_id: 1,
        current_user_fullname: 'John Doe',
      };
    });

    it('calls mutation succesfully and adds the award emoji with proper user details', () => {
      createComponent({
        awardMutationHandler: awardEmojiAddSuccessHandler,
        awardEmoji: {
          ...mockAwardsWidget,
          nodes: [mockAwardEmojiThumbsUp],
        },
      });

      findAwardsList().vm.$emit('award', EMOJI_THUMBSUP);

      expect(awardEmojiAddSuccessHandler).toHaveBeenCalledWith({
        input: {
          awardableId: mockWorkItem.id,
          name: EMOJI_THUMBSUP,
        },
      });
    });
  });
});
