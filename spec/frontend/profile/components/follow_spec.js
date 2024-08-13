import {
  GlAvatarLabeled,
  GlAvatarLink,
  GlEmptyState,
  GlLoadingIcon,
  GlPagination,
} from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import users from 'test_fixtures/api/users/followers/get.json';
import Follow from '~/profile/components/follow.vue';
import { DEFAULT_PER_PAGE } from '~/api';
import { isCurrentUser } from '~/lib/utils/common_utils';

jest.mock('~/rest_api');
jest.mock('~/lib/utils/common_utils');

describe('FollowersTab', () => {
  let wrapper;

  const defaultPropsData = {
    users,
    loading: false,
    page: 1,
    totalItems: 50,
    currentUserEmptyStateTitle: 'UserProfile|You do not have any followers',
    visitorEmptyStateTitle: "UserProfile|This user doesn't have any followers",
  };

  const defaultProvide = {
    followEmptyState: '/illustrations/empty-state/empty-friends-md.svg',
    userId: '1',
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMount(Follow, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
      provide: defaultProvide,
    });
  };

  const findPagination = () => wrapper.findComponent(GlPagination);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  describe('when `loading` prop is `true`', () => {
    it('renders loading icon', () => {
      createComponent({ propsData: { loading: true } });

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });

  describe('when `loading` prop is `false`', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders users', () => {
      const avatarLinksHref = wrapper
        .findAllComponents(GlAvatarLink)
        .wrappers.map((avatarLinkWrapper) => avatarLinkWrapper.attributes('href'));
      const expectedAvatarLinksHref = users.map((user) => user.web_url);

      const avatarLabeledProps = wrapper
        .findAllComponents(GlAvatarLabeled)
        .wrappers.map((avatarLabeledWrapper) => ({
          label: avatarLabeledWrapper.props('label'),
          subLabel: avatarLabeledWrapper.props('subLabel'),
          size: avatarLabeledWrapper.attributes('size'),
          entityName: avatarLabeledWrapper.attributes('entity-name'),
          entityId: avatarLabeledWrapper.attributes('entity-id'),
          src: avatarLabeledWrapper.attributes('src'),
        }));
      const expectedAvatarLabeledProps = users.map((user) => ({
        src: user.avatar_url,
        size: '48',
        entityId: user.id.toString(),
        entityName: user.name,
        label: user.name,
        subLabel: user.username,
      }));

      expect(avatarLinksHref).toEqual(expectedAvatarLinksHref);
      expect(avatarLabeledProps).toEqual(expectedAvatarLabeledProps);
    });

    it('renders `GlPagination` and passes correct props', () => {
      expect(wrapper.findComponent(GlPagination).props()).toMatchObject({
        align: 'center',
        value: defaultPropsData.page,
        totalItems: defaultPropsData.totalItems,
        perPage: DEFAULT_PER_PAGE,
      });
    });

    describe('when `GlPagination` emits `input` event', () => {
      it('emits `pagination-input` event', () => {
        const nextPage = defaultPropsData.page + 1;

        findPagination().vm.$emit('input', nextPage);

        expect(wrapper.emitted('pagination-input')).toEqual([[nextPage]]);
      });
    });

    describe('when the users prop is empty', () => {
      describe('when user is the current user', () => {
        beforeEach(() => {
          isCurrentUser.mockImplementation(() => true);
          createComponent({ propsData: { users: [] } });
        });

        it('displays empty state with correct message', () => {
          expect(findEmptyState().props()).toMatchObject({
            svgPath: defaultProvide.followEmptyState,
            title: defaultPropsData.currentUserEmptyStateTitle,
          });
        });
      });

      describe('when user is a visitor', () => {
        beforeEach(() => {
          isCurrentUser.mockImplementation(() => false);
          createComponent({ propsData: { users: [] } });
        });

        it('displays empty state with correct message', () => {
          expect(findEmptyState().props()).toMatchObject({
            svgPath: defaultProvide.followEmptyState,
            title: defaultPropsData.visitorEmptyStateTitle,
          });
        });
      });
    });
  });
});
