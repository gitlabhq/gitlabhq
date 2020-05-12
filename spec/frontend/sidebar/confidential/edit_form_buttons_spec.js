import { shallowMount } from '@vue/test-utils';
import EditFormButtons from '~/sidebar/components/confidential/edit_form_buttons.vue';

describe('Edit Form Buttons', () => {
  let wrapper;
  const findConfidentialToggle = () => wrapper.find('[data-testid="confidential-toggle"]');

  const createComponent = props => {
    wrapper = shallowMount(EditFormButtons, {
      propsData: {
        updateConfidentialAttribute: () => {},
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when not confidential', () => {
    it('renders Turn On in the ', () => {
      createComponent({
        isConfidential: false,
      });

      expect(findConfidentialToggle().text()).toBe('Turn On');
    });
  });

  describe('when confidential', () => {
    it('renders on or off text based on confidentiality', () => {
      createComponent({
        isConfidential: true,
      });

      expect(findConfidentialToggle().text()).toBe('Turn Off');
    });
  });
});
