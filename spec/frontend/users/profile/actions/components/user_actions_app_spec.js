import { GlDisclosureDropdown } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import UserActionsApp from '~/users/profile/actions/components/user_actions_app.vue';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';

describe('User Actions App', () => {
  let wrapper;

  const USER_ID = 'test-id';
  const DEFAULT_SUBSCRIPTION_PATH = '';

  const createWrapper = (propsData = {}) => {
    wrapper = mountExtended(UserActionsApp, {
      propsData: {
        userId: USER_ID,
        rssSubscriptionPath: DEFAULT_SUBSCRIPTION_PATH,
        ...propsData,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findActions = () => wrapper.findAllByTestId('disclosure-dropdown-item');
  const findAction = (position = 0) => findActions().at(position);
  const findSubscriptionLink = () => wrapper.findByTestId('user-profile-rss-subscription-link');

  it('shows dropdown', () => {
    createWrapper();
    expect(findDropdown().exists()).toBe(true);
  });

  describe('shows user action items', () => {
    it('should show items without RSS subscriptions', () => {
      createWrapper();
      expect(findActions()).toHaveLength(1);
    });

    it('should show items with RSS subscriptions', () => {
      createWrapper({
        rssSubscriptionPath: '/test/path',
      });
      expect(findActions()).toHaveLength(2);
    });

    it('should show items with report abuse', () => {
      createWrapper({
        rssSubscriptionPath: '/test/path',
        reportedUserId: 1,
        reportedFromUrl: '/report/path',
      });
      expect(findActions()).toHaveLength(3);
    });
  });

  it('shows copy user id action', () => {
    createWrapper();
    expect(findAction().text()).toBe(`Copy user ID: ${USER_ID}`);
    expect(findAction().find('button').attributes('data-clipboard-text')).toBe(USER_ID);
  });

  it('shows subscription link when subscription url was presented', () => {
    const testSubscriptionPath = '/test/path';

    createWrapper({
      rssSubscriptionPath: testSubscriptionPath,
    });

    const rssLink = findSubscriptionLink();
    expect(rssLink.exists()).toBe(true);
    expect(rssLink.attributes('href')).toBe(testSubscriptionPath);
    expect(rssLink.text()).toBe('Subscribe');
  });

  it('shows report abuse action when reported user id was presented', () => {
    const reportUrl = '/path/to/report';
    const reportUserId = 1;
    createWrapper({
      rssSubscriptionPath: '/test/path',
      reportedUserId: reportUserId,
      reportedFromUrl: reportUrl,
    });
    const abuseCategorySelector = wrapper.findComponent(AbuseCategorySelector);
    expect(abuseCategorySelector.exists()).toBe(true);
    expect(abuseCategorySelector.props()).toEqual({
      reportedUserId: reportUserId,
      reportedFromUrl: reportUrl,
      showDrawer: false,
    });
  });
});
