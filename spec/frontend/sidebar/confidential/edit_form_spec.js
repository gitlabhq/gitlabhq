import { shallowMount } from '@vue/test-utils';
import EditForm from '~/sidebar/components/confidential/edit_form.vue';

describe('Edit Form Dropdown', () => {
  let wrapper;
  const toggleForm = () => {};
  const updateConfidentialAttribute = () => {};

  const createComponent = props => {
    wrapper = shallowMount(EditForm, {
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when not confidential', () => {
    it('renders "You are going to turn off the confidentiality." in the ', () => {
      createComponent({
        isConfidential: false,
        toggleForm,
        updateConfidentialAttribute,
      });

      expect(wrapper.find('p').text()).toContain('You are going to turn on the confidentiality.');
    });
  });

  describe('when confidential', () => {
    it('renders on or off text based on confidentiality', () => {
      createComponent({
        isConfidential: true,
        toggleForm,
        updateConfidentialAttribute,
      });

      expect(wrapper.find('p').text()).toContain('You are going to turn off the confidentiality.');
    });
  });
});
