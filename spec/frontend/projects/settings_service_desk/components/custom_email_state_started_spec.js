import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import CustomEmailStateStarted from '~/projects/settings_service_desk/components/custom_email_state_started.vue';

describe('CustomEmailStateStarted', () => {
  let wrapper;

  const defaultProps = {
    customEmail: 'user@example.com',
    smtpAddress: 'smtp.example.com',
    submitting: false,
  };

  const findButton = () => wrapper.findComponent(GlButton);

  const createWrapper = (props = {}) => {
    wrapper = mount(CustomEmailStateStarted, { propsData: { ...defaultProps, ...props } });
  };

  it('displays the custom email address and smtp address in the body', () => {
    createWrapper();
    const text = wrapper.text();

    expect(text).toContain(defaultProps.customEmail);
    expect(text).toContain(defaultProps.smtpAddress);
  });

  describe('button', () => {
    it('emits a reset event when button clicked', () => {
      createWrapper();
      findButton().trigger('click');

      expect(wrapper.emitted('reset')).toEqual([[]]);
    });

    it('does not emit event when button clicked and submitting', () => {
      createWrapper({ submitting: true });
      findButton().trigger('click');

      expect(wrapper.emitted('reset')).toEqual(undefined);
    });
  });
});
