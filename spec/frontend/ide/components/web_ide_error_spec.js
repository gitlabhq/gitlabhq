import { GlAlert, GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import WebIdeError from '~/ide/components/web_ide_error.vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';

const findButtons = (wrapper) => wrapper.findAllComponents(GlButton);

describe('WebIdeError', () => {
  const MOCK_SIGN_OUT_PATH = '/users/sign_out';

  let wrapper;

  useMockLocationHelper();
  function createWrapper() {
    wrapper = mount(WebIdeError, {
      propsData: {
        signOutPath: MOCK_SIGN_OUT_PATH,
      },
    });
  }

  it('renders alert component', () => {
    createWrapper();
    const alert = wrapper.findComponent(GlAlert);

    expect(alert.text()).toMatchInterpolatedText(
      'Failed to load the Web IDE For more information, see the developer console. Try to reload the page or sign out and in again. If the issue persists, report a problem. Reload Sign out',
    );
  });

  it('renders reload page button', () => {
    createWrapper();
    const reloadButton = findButtons(wrapper).at(0);

    expect(reloadButton.text()).toEqual('Reload');

    reloadButton.vm.$emit('click');
    expect(window.location.reload).toHaveBeenCalled();
  });

  it('renders sign out button', () => {
    createWrapper();
    const signOutButton = findButtons(wrapper).at(1);

    expect(signOutButton.text()).toEqual('Sign out');
    expect(signOutButton.attributes()).toMatchObject({
      'data-method': 'post',
      href: MOCK_SIGN_OUT_PATH,
    });
  });
});
