import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import ErrorsAlert from '~/vue_shared/components/errors_alert.vue';

describe('ErrorsAlert', () => {
  let wrapper;
  const mockError1 = 'The item could not be created';
  const mockError2 = 'The item could not be updated';

  const findErrorAlert = () => wrapper.findComponent(GlAlert);

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(ErrorsAlert, {
      propsData: {
        ...props,
      },
    });
  };

  describe('Initial Rendering', () => {
    it('does not render error alert', () => {
      createWrapper();

      expect(findErrorAlert().exists()).toBe(false);
    });

    it('renders error alert when there is one error', () => {
      createWrapper({ errors: [mockError1] });

      expect(findErrorAlert().text()).toBe(mockError1);
    });

    it('renders error alert with list for multiple errors', () => {
      createWrapper({ errors: [mockError1, mockError2] });
      const foundErrors = findErrorAlert().findAll('li');
      expect(foundErrors).toHaveLength(2);
      expect(foundErrors.at(0).text()).toBe(mockError1);
      expect(foundErrors.at(1).text()).toBe(mockError2);
    });

    it('renders the default CSS class', () => {
      createWrapper({ errors: [mockError1] });

      expect(findErrorAlert().attributes('class')).toBe('gl-mb-5');
    });

    it('does not render the default CSS class when overridden', () => {
      createWrapper({ errors: [mockError1], alertClass: 'gl-mb-4' });

      expect(findErrorAlert().attributes('class')).toBe('gl-mb-4');
    });
  });

  describe('when the component receives an error after initial rendering', () => {
    const originalScrollIntoView = HTMLElement.prototype.scrollIntoView;
    const scrollIntoViewMock = jest.fn();

    beforeEach(() => {
      HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;
    });

    afterEach(() => {
      HTMLElement.prototype.scrollIntoView = originalScrollIntoView;
    });

    it('scrolls to error alert when errors are set', async () => {
      createWrapper();
      await wrapper.setProps({ errors: ['Error occurred'] });
      await nextTick();

      expect(scrollIntoViewMock).toHaveBeenCalledWith({
        behavior: 'smooth',
        block: 'center',
      });
    });

    describe('but the property to scrollOnError is false', () => {
      it('does not to error alert when errors are set', async () => {
        createWrapper({ scrollOnError: false });
        await wrapper.setProps({ errors: ['Error occurred'] });
        await nextTick();

        expect(scrollIntoViewMock).not.toHaveBeenCalledWith({
          behavior: 'smooth',
          block: 'center',
        });
      });
    });
  });

  describe('Interactions', () => {
    describe('when dismissing the alert', () => {
      beforeEach(() => {
        createWrapper({ errors: [mockError1] });
      });

      it('emits dismiss event when clicked on dismiss icon', () => {
        findErrorAlert().vm.$emit('dismiss');

        expect(wrapper.emitted('dismiss')).toHaveLength(1);
      });
    });
  });
});
