import { GlButton, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import CiIconBadge from '~/vue_shared/components/ci_badge_link.vue';
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
    itemName: 'job',
    itemId: 123,
    time: '2017-05-08T14:57:39.781Z',
    user: {
      web_url: 'path',
      name: 'Foo',
      username: 'foobar',
      email: 'foo@bar.com',
      avatar_url: 'link',
    },
    hasSidebarButton: true,
  };

  const findIconBadge = () => wrapper.findComponent(CiIconBadge);
  const findTimeAgo = () => wrapper.findComponent(TimeagoTooltip);
  const findUserLink = () => wrapper.findComponent(GlLink);
  const findSidebarToggleBtn = () => wrapper.findComponent(GlButton);
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

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('render', () => {
    beforeEach(() => {
      createComponent();
    });

    it('should render status badge', () => {
      expect(findIconBadge().exists()).toBe(true);
    });

    it('should render item name and id', () => {
      expect(findHeaderItemText().text()).toBe('job #123');
    });

    it('should render timeago date', () => {
      expect(findTimeAgo().exists()).toBe(true);
    });

    it('should render user icon and name', () => {
      expect(findUserLink().text()).toContain(defaultProps.user.name);
    });

    it('should render sidebar toggle button', () => {
      expect(findSidebarToggleBtn().exists()).toBe(true);
    });

    it('should not render header action buttons when slot is empty', () => {
      expect(findActionButtons().exists()).toBe(false);
    });
  });

  describe('slot', () => {
    it('should render header action buttons', () => {
      createComponent({}, { slots: { default: 'Test Actions' } });

      expect(findActionButtons().exists()).toBe(true);
      expect(findActionButtons().text()).toBe('Test Actions');
    });
  });

  describe('shouldRenderTriggeredLabel', () => {
    it('should render created keyword when the shouldRenderTriggeredLabel is false', () => {
      createComponent({ shouldRenderTriggeredLabel: false });

      expect(wrapper.text()).toContain('created');
      expect(wrapper.text()).not.toContain('triggered');
    });
  });
});
