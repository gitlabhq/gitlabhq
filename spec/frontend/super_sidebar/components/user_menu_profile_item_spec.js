import { GlDisclosureDropdownItem, GlTooltip } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import UserMenuProfileItem from '~/super_sidebar/components/user_menu_profile_item.vue';
import { userMenuMockData, userMenuMockStatus } from '../mock_data';

describe('UserMenuProfileItem component', () => {
  let wrapper;

  const findGlDisclosureDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findGlTooltip = () => wrapper.findComponent(GlTooltip);
  const findUserStatus = () => wrapper.findByTestId('user-menu-status');

  const GlEmoji = { template: '<img/>' };

  const createWrapper = (userDataChanges = {}) => {
    wrapper = mountExtended(UserMenuProfileItem, {
      propsData: {
        user: {
          ...userMenuMockData,
          ...userDataChanges,
        },
      },
      stubs: {
        GlEmoji,
        GlDisclosureDropdownItem,
      },
    });
  };

  beforeEach(() => {
    createWrapper();
  });

  it('renders menu item', () => {
    expect(findGlDisclosureDropdownItem().exists()).toBe(true);
  });

  it('passes the item to the disclosure dropdown item', () => {
    expect(findGlDisclosureDropdownItem().props('item')).toEqual(
      expect.objectContaining({
        text: userMenuMockData.name,
        href: userMenuMockData.link_to_profile,
      }),
    );
  });

  it("renders user's name", () => {
    expect(findGlDisclosureDropdownItem().text()).toContain(userMenuMockData.name);
  });

  it("renders user's username", () => {
    expect(findGlDisclosureDropdownItem().text()).toContain(userMenuMockData.username);
  });

  describe('Busy status', () => {
    it('should not render "Busy" when user is NOT busy', () => {
      expect(findGlDisclosureDropdownItem().text()).not.toContain('Busy');
    });
    it('should  render "Busy" when user is busy', () => {
      createWrapper({ status: { customized: true, busy: true } });

      expect(findGlDisclosureDropdownItem().text()).toContain('Busy');
    });
  });

  describe('User status', () => {
    describe('when not customized', () => {
      it('should not render it', () => {
        expect(findUserStatus().exists()).toBe(false);
      });
    });

    describe('when customized', () => {
      beforeEach(() => {
        createWrapper({ status: { ...userMenuMockStatus, customized: true } });
      });

      it('should render it', () => {
        expect(findUserStatus().exists()).toBe(true);
      });

      it('should render status emoji', () => {
        expect(findUserStatus().findComponent(GlEmoji).attributes('data-name')).toBe(
          userMenuMockData.status.emoji,
        );
      });

      it('should render status message', () => {
        expect(findUserStatus().html()).toContain(userMenuMockData.status.message_html);
      });

      it("sets the tooltip's target to the status container", () => {
        expect(findGlTooltip().props('target')?.()).toBe(findUserStatus().element);
      });

      describe('Tooltip', () => {
        it('renders the tooltip when message has some text', () => {
          createWrapper({
            status: { ...userMenuMockStatus, customized: true, message_html: 'Has text' },
          });
          expect(findGlTooltip().exists()).toBe(true);
        });

        it('does not render the tooltip when message is empty', () => {
          createWrapper({
            status: { ...userMenuMockStatus, customized: true, message_html: '' },
          });
          expect(findGlTooltip().exists()).toBe(false);
        });
      });
    });
  });

  describe('Tracking', () => {
    it('sets the tracking attributes', () => {
      expect(findGlDisclosureDropdownItem().find('a').attributes()).toEqual(
        expect.objectContaining({
          'data-track-property': 'nav_user_menu',
          'data-track-action': 'click_link',
          'data-track-label': 'user_profile',
        }),
      );
    });
  });
});
