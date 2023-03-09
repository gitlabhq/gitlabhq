import { GlButton, GlAvatarLink, GlTooltip } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';
import HeaderCi from '~/vue_shared/components/header_ci_component.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

describe('Header CI Component', () => {
  let wrapper;

  const defaultProps = {
    status: {
      group: 'failed',
      icon: 'status_failed',
      label: 'failed',
      text: 'failed',
      details_path: 'path',
    },
    time: '2017-05-08T14:57:39.781Z',
    user: {
      id: 1234,
      web_url: 'path',
      name: 'Foo',
      username: 'foobar',
      email: 'foo@bar.com',
      avatar_url: 'link',
    },
    hasSidebarButton: true,
  };

  const findCiBadgeLink = () => wrapper.findComponent(CiBadgeLink);
  const findTimeAgo = () => wrapper.findComponent(TimeagoTooltip);
  const findUserLink = () => wrapper.findComponent(GlAvatarLink);
  const findSidebarToggleBtn = () => wrapper.findComponent(GlButton);
  const findStatusTooltip = () => wrapper.findComponent(GlTooltip);
  const findActionButtons = () => wrapper.findByTestId('ci-header-action-buttons');
  const findHeaderItemText = () => wrapper.findByTestId('ci-header-item-text');

  const createComponent = (props, slots) => {
    wrapper = extendedWrapper(
      shallowMount(HeaderCi, {
        propsData: {
          ...defaultProps,
          ...props,
        },
        ...slots,
      }),
    );
  };

  describe('render', () => {
    beforeEach(() => {
      createComponent({ itemName: 'Pipeline' });
    });

    it('should render status badge', () => {
      expect(findCiBadgeLink().exists()).toBe(true);
    });

    it('should render timeago date', () => {
      expect(findTimeAgo().exists()).toBe(true);
    });

    it('should render sidebar toggle button', () => {
      expect(findSidebarToggleBtn().exists()).toBe(true);
    });

    it('should not render header action buttons when slot is empty', () => {
      expect(findActionButtons().exists()).toBe(false);
    });
  });

  describe('user avatar', () => {
    beforeEach(() => {
      createComponent({ itemName: 'Pipeline' });
    });

    it('contains the username', () => {
      expect(findUserLink().text()).toContain(defaultProps.user.username);
    });

    it('has the correct HTML attributes', () => {
      expect(findUserLink().attributes()).toMatchObject({
        'data-user-id': defaultProps.user.id.toString(),
        'data-username': defaultProps.user.username,
        'data-name': defaultProps.user.name,
        href: defaultProps.user.web_url,
      });
    });

    describe('when the user has a status', () => {
      const STATUS_MESSAGE = 'Working on exciting features...';

      beforeEach(() => {
        createComponent({
          itemName: 'Pipeline',
          user: { ...defaultProps.user, status: { message: STATUS_MESSAGE } },
        });
      });

      it('renders a tooltip', () => {
        expect(findStatusTooltip().text()).toBe(STATUS_MESSAGE);
      });
    });

    describe('with data from GraphQL', () => {
      const userId = 1;

      beforeEach(() => {
        createComponent({
          itemName: 'Pipeline',
          user: { ...defaultProps.user, id: `gid://gitlab/User/${1}` },
        });
      });

      it('has the correct user id', () => {
        expect(findUserLink().attributes('data-user-id')).toBe(userId.toString());
      });
    });

    describe('with data from REST', () => {
      it('has the correct user id', () => {
        expect(findUserLink().attributes('data-user-id')).toBe(defaultProps.user.id.toString());
      });
    });
  });

  describe('with item id', () => {
    beforeEach(() => {
      createComponent({ itemName: 'Pipeline', itemId: '123' });
    });

    it('should render item name and id', () => {
      expect(findHeaderItemText().text()).toBe('Pipeline #123');
    });
  });

  describe('without item id', () => {
    beforeEach(() => {
      createComponent({ itemName: 'Job build_job' });
    });

    it('should render item name', () => {
      expect(findHeaderItemText().text()).toBe('Job build_job');
    });
  });

  describe('slot', () => {
    it('should render header action buttons', () => {
      createComponent({ itemName: 'Job build_job' }, { slots: { default: 'Test Actions' } });

      expect(findActionButtons().exists()).toBe(true);
      expect(findActionButtons().text()).toBe('Test Actions');
    });
  });

  describe('shouldRenderTriggeredLabel', () => {
    it('should render created keyword when the shouldRenderTriggeredLabel is false', () => {
      createComponent({ shouldRenderTriggeredLabel: false, itemName: 'Job build_job' });

      expect(wrapper.text()).toContain('created');
      expect(wrapper.text()).not.toContain('triggered');
    });
  });
});
