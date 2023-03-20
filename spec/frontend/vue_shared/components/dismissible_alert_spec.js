import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DismissibleAlert from '~/vue_shared/components/dismissible_alert.vue';

const TEST_HTML = 'Hello World! <strong>Foo</strong>';

describe('vue_shared/components/dismissible_alert', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(DismissibleAlert, {
      propsData: {
        html: TEST_HTML,
        ...props,
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows alert', () => {
      expect(findAlert().exists()).toBe(true);
    });

    it('shows given HTML', () => {
      expect(findAlert().html()).toContain(TEST_HTML);
    });

    describe('when dismissed', () => {
      beforeEach(() => {
        findAlert().vm.$emit('dismiss');
      });

      it('hides the alert', () => {
        expect(findAlert().exists()).toBe(false);
      });

      it('emmits alertDismissed', () => {
        expect(wrapper.emitted()).toHaveProperty('alertDismissed');
      });
    });
  });

  describe('with additional props', () => {
    const testAlertProps = {
      dismissible: true,
      title: 'Mock Title',
      primaryButtonText: 'Lorem ipsum',
      primaryButtonLink: '/lorem/ipsum',
      variant: 'warning',
    };

    beforeEach(() => {
      createComponent(testAlertProps);
    });

    it('passes other props', () => {
      expect(findAlert().props()).toEqual(expect.objectContaining(testAlertProps));
    });
  });

  describe('with unsafe HTML', () => {
    beforeEach(() => {
      createComponent({ html: '<a onclick="alert("XSS")">Link</a>' });
    });

    it('removes unsafe HTML', () => {
      expect(findAlert().html()).toContain('<a>Link</a>');
    });
  });
});
