import { GlBadge, GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import following from 'test_fixtures/api/users/following/get.json';
import FollowingTab from '~/profile/components/following_tab.vue';
import Follow from '~/profile/components/follow.vue';
import { getUserFollowing } from '~/rest_api';
import { createAlert } from '~/alert';
import waitForPromises from 'helpers/wait_for_promises';

const MOCK_FOLLOWEES_COUNT = 2;
const MOCK_TOTAL_FOLLOWING = 6;
const MOCK_PAGE = 1;

jest.mock('~/rest_api');
jest.mock('~/alert');

describe('FollowingTab', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(FollowingTab, {
      provide: {
        followeesCount: MOCK_FOLLOWEES_COUNT,
        userId: 1,
      },
      stubs: {
        GlTab,
      },
    });
  };

  const findGlBadge = () => wrapper.findComponent(GlBadge);
  const findFollow = () => wrapper.findComponent(Follow);

  describe('when API request is loading', () => {
    beforeEach(() => {
      getUserFollowing.mockReturnValueOnce(new Promise(() => {}));
      createComponent();
    });

    it('renders `Follow` component and sets `loading` prop to `true`', () => {
      expect(findFollow().props('loading')).toBe(true);
    });
  });

  describe('when API request is successful', () => {
    beforeEach(() => {
      getUserFollowing.mockResolvedValueOnce({
        data: following,
        headers: { 'X-TOTAL': `${MOCK_TOTAL_FOLLOWING}` },
      });
      createComponent();
    });

    it('renders `GlTab` and sets title', () => {
      expect(wrapper.findComponent(GlTab).text()).toContain('Following');
    });

    it('renders `GlBadge`, sets content', () => {
      expect(findGlBadge().text()).toBe(`${MOCK_FOLLOWEES_COUNT}`);
    });

    it('renders `Follow` component and passes correct props', () => {
      expect(findFollow().props()).toMatchObject({
        users: following,
        loading: false,
        page: MOCK_PAGE,
        totalItems: MOCK_TOTAL_FOLLOWING,
        currentUserEmptyStateTitle: FollowingTab.i18n.currentUserEmptyStateTitle,
        visitorEmptyStateTitle: FollowingTab.i18n.visitorEmptyStateTitle,
      });
    });

    describe('when `Follow` component emits `pagination-input` event', () => {
      it('calls API and updates `users` and `page` props', async () => {
        const NEXT_PAGE = MOCK_PAGE + 1;
        const NEXT_PAGE_FOLLOWING = [{ id: 999, name: 'page 2 following' }];

        getUserFollowing.mockResolvedValueOnce({
          data: NEXT_PAGE_FOLLOWING,
          headers: { 'X-TOTAL': `${MOCK_TOTAL_FOLLOWING}` },
        });

        findFollow().vm.$emit('pagination-input', NEXT_PAGE);

        await waitForPromises();

        expect(findFollow().props()).toMatchObject({
          users: NEXT_PAGE_FOLLOWING,
          loading: false,
          page: NEXT_PAGE,
          totalItems: MOCK_TOTAL_FOLLOWING,
        });
      });
    });
  });

  describe('when API request is not successful', () => {
    beforeEach(() => {
      getUserFollowing.mockRejectedValueOnce(new Error());
      createComponent();
    });

    it('shows error alert', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: FollowingTab.i18n.errorMessage,
        error: new Error(),
        captureError: true,
      });
    });
  });
});
