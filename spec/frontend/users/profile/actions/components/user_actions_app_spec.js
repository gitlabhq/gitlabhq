import { GlDisclosureDropdown } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import UserActionsApp from '~/users/profile/actions/components/user_actions_app.vue';

describe('User Actions App', () => {
  let wrapper;

  const USER_ID = 'test-id';

  const createWrapper = (propsData = {}) => {
    wrapper = mountExtended(UserActionsApp, {
      propsData: {
        userId: USER_ID,
        ...propsData,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findActions = () => wrapper.findAllByTestId('disclosure-dropdown-item');
  const findAction = (position = 0) => findActions().at(position);

  it('shows dropdown', () => {
    createWrapper();
    expect(findDropdown().exists()).toBe(true);
  });

  it('shows actions correctly', () => {
    createWrapper();
    expect(findActions()).toHaveLength(1);
  });

  it('shows copy user id action', () => {
    createWrapper();
    expect(findAction().text()).toBe(`Copy user ID: ${USER_ID}`);
    expect(findAction().findComponent('button').attributes('data-clipboard-text')).toBe(USER_ID);
  });
});
