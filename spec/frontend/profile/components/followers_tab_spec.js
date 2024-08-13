import { GlBadge, GlTab } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import followers from 'test_fixtures/api/users/followers/get.json';
import FollowersTab from '~/profile/components/followers_tab.vue';
import Follow from '~/profile/components/follow.vue';
import { getUserFollowers } from '~/rest_api';
import { createAlert } from '~/alert';
import waitForPromises from 'helpers/wait_for_promises';
import { stubComponent } from 'helpers/stub_component';

jest.mock('~/rest_api');
jest.mock('~/alert');

describe('FollowersTab', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(FollowersTab, {
      provide: {
        followersCount: 2,
        userId: 1,
      },
      stubs: {
        GlTab: stubComponent(GlTab, {
          template: `
            <li>
              <slot name="title"></slot>
              <slot></slot>
            </li>
          `,
        }),
      },
    });
  };

  const findGlBadge = () => wrapper.findComponent(GlBadge);
  const findFollow = () => wrapper.findComponent(Follow);

  describe('when API request is loading', () => {
    beforeEach(() => {
      getUserFollowers.mockReturnValueOnce(new Promise(() => {}));
      createComponent();
    });

    it('renders `Follow` component and sets `loading` prop to `true`', () => {
      expect(findFollow().props('loading')).toBe(true);
    });
  });

  describe('when API request is successful', () => {
    beforeEach(async () => {
      getUserFollowers.mockResolvedValueOnce({
        data: followers,
        headers: { 'X-TOTAL': '6' },
      });
      createComponent();

      await waitForPromises();
    });

    it('renders `GlTab` and sets title', () => {
      expect(wrapper.findComponent(GlTab).text()).toContain('Followers');
    });

    it('renders `GlBadge`, sets content', () => {
      expect(findGlBadge().text()).toBe('2');
    });

    it('renders `Follow` component and passes correct props', () => {
      expect(findFollow().props()).toMatchObject({
        users: followers,
        loading: false,
        page: 1,
        totalItems: 6,
        currentUserEmptyStateTitle: FollowersTab.i18n.currentUserEmptyStateTitle,
        visitorEmptyStateTitle: FollowersTab.i18n.visitorEmptyStateTitle,
      });
    });

    describe('when `Follow` component emits `pagination-input` event', () => {
      it('calls API and updates `users` and `page` props', async () => {
        const lastFollower = followers.at(-1);
        const paginationFollowers = [
          {
            ...lastFollower,
            id: lastFollower.id + 1,
            name: 'page 2 follower',
          },
        ];

        getUserFollowers.mockResolvedValueOnce({
          data: paginationFollowers,
          headers: { 'X-TOTAL': '6' },
        });

        findFollow().vm.$emit('pagination-input', 2);

        await waitForPromises();

        expect(findFollow().props()).toMatchObject({
          users: paginationFollowers,
          loading: false,
          page: 2,
          totalItems: 6,
        });
      });
    });
  });

  describe('when API request is not successful', () => {
    beforeEach(async () => {
      getUserFollowers.mockRejectedValueOnce(new Error());
      createComponent();

      await waitForPromises();
    });

    it('shows error alert', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: FollowersTab.i18n.errorMessage,
        error: new Error(),
        captureError: true,
      });
    });
  });
});
