import { GlAvatarLabeled, GlAvatarLink, GlLoadingIcon, GlPagination } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import users from 'test_fixtures/api/users/followers/get.json';
import Follow from '~/profile/components/follow.vue';
import { DEFAULT_PER_PAGE } from '~/api';

jest.mock('~/rest_api');

describe('FollowersTab', () => {
  let wrapper;

  const defaultPropsData = {
    users,
    loading: false,
    page: 1,
    totalItems: 50,
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMount(Follow, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
    });
  };

  const findPagination = () => wrapper.findComponent(GlPagination);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

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
        prevText: Follow.i18n.prev,
        nextText: Follow.i18n.next,
      });
    });

    describe('when `GlPagination` emits `input` event', () => {
      it('emits `pagination-input` event', () => {
        const nextPage = defaultPropsData.page + 1;

        findPagination().vm.$emit('input', nextPage);

        expect(wrapper.emitted('pagination-input')).toEqual([[nextPage]]);
      });
    });
  });
});
