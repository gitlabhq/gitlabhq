import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DismissibleAlert from '~/vue_shared/components/dismissible_alert.vue';

const TEST_HTML = 'Hello World! <strong>Foo</strong>';

describe('vue_shared/components/dismissible_alert', () => {
  const testAlertProps = {
    primaryButtonText: 'Lorem ipsum',
    primaryButtonLink: '/lorem/ipsum',
  };

  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMount(DismissibleAlert, {
      propsData: {
        html: TEST_HTML,
        ...testAlertProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findAlert = () => wrapper.find(GlAlert);

  describe('with default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows alert', () => {
      const alert = findAlert();

      expect(alert.exists()).toBe(true);
      expect(alert.props()).toEqual(expect.objectContaining(testAlertProps));
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
    });
  });
});
