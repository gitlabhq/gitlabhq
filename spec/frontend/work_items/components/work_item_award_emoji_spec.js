import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { isLoggedIn } from '~/lib/utils/common_utils';
import AwardList from '~/vue_shared/components/awards_list.vue';
import WorkItemAwardEmoji from '~/work_items/components/work_item_award_emoji.vue';
import updateAwardEmojiMutation from '~/work_items/graphql/update_award_emoji.mutation.graphql';
import projectWorkItemAwardEmojiQuery from '~/work_items/graphql/award_emoji.query.graphql';
import {
  DEFAULT_PAGE_SIZE_EMOJIS,
  I18N_WORK_ITEM_FETCH_AWARD_EMOJI_ERROR,
} from '~/work_items/constants';
import { EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN } from '~/emoji/constants';

import {
  workItemByIidResponseFactory,
  mockAwardsWidget,
  mockAwardEmojiThumbsUp,
  getAwardEmojiResponse,
  mockMoreThanDefaultAwardEmojisWidget,
} from '../mock_data';

jest.mock('~/lib/utils/common_utils');
jest.mock('~/work_items/constants', () => ({
  ...jest.requireActual('~/work_items/constants'),
  DEFAULT_PAGE_SIZE_EMOJIS: 5,
}));

Vue.use(VueApollo);

describe('WorkItemAwardEmoji component', () => {
  let wrapper;
  let mockApolloProvider;

  const mutationErrorMessage = 'Failed to update the award';

  const workItemQueryResponse = workItemByIidResponseFactory();
  const mockWorkItem = workItemQueryResponse.data.workspace.workItem;

  const awardEmojiQuerySuccessHandler = jest.fn().mockResolvedValue(workItemQueryResponse);
  const awardEmojiQueryEmptyHandler = jest.fn().mockResolvedValue(
    workItemByIidResponseFactory({
      awardEmoji: {
        ...mockAwardsWidget,
        nodes: [],
      },
    }),
  );
  const awardEmojiQueryThumbsUpHandler = jest.fn().mockResolvedValue(
    workItemByIidResponseFactory({
      awardEmoji: {
        ...mockAwardsWidget,
        nodes: [mockAwardEmojiThumbsUp],
      },
    }),
  );
  const awardEmojiQueryFailureHandler = jest
    .fn()
    .mockRejectedValue(new Error(I18N_WORK_ITEM_FETCH_AWARD_EMOJI_ERROR));

  const awardEmojiAddSuccessHandler = jest.fn().mockResolvedValue(getAwardEmojiResponse(true));
  const awardEmojiRemoveSuccessHandler = jest.fn().mockResolvedValue(getAwardEmojiResponse(false));
  const awardEmojiUpdateFailureHandler = jest
    .fn()
    .mockRejectedValue(new Error(mutationErrorMessage));

  const mockAwardEmojiDifferentUser = {
    name: EMOJI_THUMBS_UP,
    __typename: 'AwardEmoji',
    user: {
      id: 'gid://gitlab/User/1',
      name: 'John Doe',
      __typename: 'UserCore',
    },
  };

  const createComponent = ({
    awardEmojiQueryHandler = awardEmojiQuerySuccessHandler,
    awardEmojiMutationHandler = awardEmojiAddSuccessHandler,
    workItemIid = '1',
  } = {}) => {
    mockApolloProvider = createMockApollo(
      [
        [projectWorkItemAwardEmojiQuery, awardEmojiQueryHandler],
        [updateAwardEmojiMutation, awardEmojiMutationHandler],
      ],
      {},
      {
        typePolicies: {
          WorkItemWidgetAwardEmoji: {
            fields: {
              // If we add any key args, the awardEmoji field becomes awardEmoji({"first":10}) and
              // kills any possibility to handle it on the widget level without hardcoding a string.
              awardEmoji: {
                keyArgs: false,
              },
            },
          },
        },
      },
    );

    wrapper = shallowMount(WorkItemAwardEmoji, {
      isLoggedIn: isLoggedIn(),
      apolloProvider: mockApolloProvider,
      propsData: {
        workItemId: 'gid://gitlab/WorkItem/1',
        workItemFullpath: 'test-project-path',
        workItemIid,
      },
    });
  };

  const findAwardsList = () => wrapper.findComponent(AwardList);

  beforeEach(async () => {
    isLoggedIn.mockReturnValue(true);
    window.gon = {
      current_user_id: 5,
      current_user_fullname: 'Dave Smith',
    };

    await createComponent();
  });

  it('renders the award-list component with default props', async () => {
    createComponent({
      awardEmojiQueryHandler: awardEmojiQueryEmptyHandler,
    });

    await waitForPromises();

    expect(findAwardsList().exists()).toBe(true);
    expect(findAwardsList().props()).toEqual({
      canAwardEmoji: true,
      currentUserId: 5,
      defaultAwards: [EMOJI_THUMBS_UP, EMOJI_THUMBS_DOWN],
      selectedClass: 'selected',
      awards: [],
    });
  });

  it('renders awards-list component with awards present', () => {
    expect(findAwardsList().props('awards')).toEqual([
      {
        name: EMOJI_THUMBS_UP,
        user: {
          id: 5,
          name: 'Dave Smith',
        },
      },
      {
        name: EMOJI_THUMBS_DOWN,
        user: {
          id: 5,
          name: 'Dave Smith',
        },
      },
    ]);
  });

  it('emits error when there is an error while fetching award emojis', async () => {
    createComponent({
      awardEmojiQueryHandler: awardEmojiQueryFailureHandler,
    });

    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([[I18N_WORK_ITEM_FETCH_AWARD_EMOJI_ERROR]]);
  });

  it('renders awards list given by multiple users', async () => {
    const mockWorkItemAwardEmojiDifferentUser = workItemByIidResponseFactory({
      awardEmoji: {
        ...mockAwardsWidget,
        nodes: [mockAwardEmojiThumbsUp, mockAwardEmojiDifferentUser],
      },
    });
    const awardEmojiWithDifferentUsersQueryHandler = jest
      .fn()
      .mockResolvedValue(mockWorkItemAwardEmojiDifferentUser);

    createComponent({
      awardEmojiQueryHandler: awardEmojiWithDifferentUsersQueryHandler,
    });

    await waitForPromises();

    expect(findAwardsList().props('awards')).toEqual([
      {
        name: EMOJI_THUMBS_UP,
        user: {
          id: 5,
          name: 'Dave Smith',
        },
      },
      {
        name: EMOJI_THUMBS_UP,
        user: {
          id: 1,
          name: 'John Doe',
        },
      },
    ]);
  });

  it.each`
    expectedAssertion | awardEmojiMutationHandler         | awardEmojiQueryHandler
    ${'added'}        | ${awardEmojiAddSuccessHandler}    | ${awardEmojiQueryEmptyHandler}
    ${'removed'}      | ${awardEmojiRemoveSuccessHandler} | ${awardEmojiQueryThumbsUpHandler}
  `(
    'calls mutation when an award emoji is $expectedAssertion',
    async ({ awardEmojiMutationHandler, awardEmojiQueryHandler }) => {
      createComponent({
        awardEmojiMutationHandler,
        awardEmojiQueryHandler,
      });

      await waitForPromises();

      findAwardsList().vm.$emit('award', EMOJI_THUMBS_UP);

      expect(awardEmojiMutationHandler).toHaveBeenCalledWith({
        input: {
          awardableId: mockWorkItem.id,
          name: EMOJI_THUMBS_UP,
        },
      });
    },
  );

  it('emits error when the update mutation fails', async () => {
    createComponent({
      awardEmojiMutationHandler: awardEmojiUpdateFailureHandler,
      awardEmojiQueryHandler: awardEmojiQueryEmptyHandler,
    });

    await waitForPromises();

    findAwardsList().vm.$emit('award', EMOJI_THUMBS_UP);

    await waitForPromises();

    expect(wrapper.emitted('error')).toEqual([[mutationErrorMessage]]);
  });

  describe('when user is not logged in', () => {
    beforeEach(async () => {
      isLoggedIn.mockReturnValue(false);

      await createComponent();
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

    it('calls mutation successfully and adds the award emoji with proper user details', async () => {
      createComponent({
        awardEmojiMutationHandler: awardEmojiAddSuccessHandler,
      });

      await waitForPromises();

      findAwardsList().vm.$emit('award', EMOJI_THUMBS_UP);

      expect(awardEmojiAddSuccessHandler).toHaveBeenCalledWith({
        input: {
          awardableId: mockWorkItem.id,
          name: EMOJI_THUMBS_UP,
        },
      });
    });
  });

  describe('pagination', () => {
    describe('when there is no next page', () => {
      const awardEmojiQuerySingleItemHandler = jest.fn().mockResolvedValue(
        workItemByIidResponseFactory({
          awardEmoji: {
            ...mockAwardsWidget,
            nodes: [mockAwardEmojiThumbsUp],
          },
        }),
      );

      it('fetch more award emojis should not be called', async () => {
        createComponent({ awardEmojiQueryHandler: awardEmojiQuerySingleItemHandler });
        await waitForPromises();

        expect(awardEmojiQuerySingleItemHandler).toHaveBeenCalledWith({
          fullPath: 'test-project-path',
          iid: '1',
          pageSize: DEFAULT_PAGE_SIZE_EMOJIS,
          after: undefined,
        });
        expect(awardEmojiQuerySingleItemHandler).toHaveBeenCalledTimes(1);
      });
    });

    describe('when there is next page', () => {
      const awardEmojisQueryMoreThanDefaultHandler = jest.fn().mockResolvedValueOnce(
        workItemByIidResponseFactory({
          awardEmoji: mockMoreThanDefaultAwardEmojisWidget,
        }),
      );

      it('fetch more award emojis should be called', async () => {
        createComponent({
          awardEmojiQueryHandler: awardEmojisQueryMoreThanDefaultHandler,
        });
        await waitForPromises();

        expect(awardEmojisQueryMoreThanDefaultHandler).toHaveBeenCalledWith({
          fullPath: 'test-project-path',
          iid: '1',
          pageSize: DEFAULT_PAGE_SIZE_EMOJIS,
          after: 'endCursor',
        });

        await nextTick();

        expect(awardEmojisQueryMoreThanDefaultHandler).toHaveBeenCalledWith({
          fullPath: 'test-project-path',
          iid: '1',
          pageSize: DEFAULT_PAGE_SIZE_EMOJIS,
          after: mockMoreThanDefaultAwardEmojisWidget.pageInfo.endCursor,
        });
        expect(awardEmojisQueryMoreThanDefaultHandler).toHaveBeenCalledTimes(2);
      });
    });
  });
});
