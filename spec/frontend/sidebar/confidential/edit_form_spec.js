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
        isLoading: false,
        fullPath: '',
        issuableType: 'issue',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when not confidential', () => {
    it('renders "You are going to turn on the confidentiality." in the ', () => {
      createComponent({
        confidential: false,
        toggleForm,
        updateConfidentialAttribute,
      });

      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('when confidential', () => {
    it('renders on or off text based on confidentiality', () => {
      createComponent({
        confidential: true,
        toggleForm,
        updateConfidentialAttribute,
      });

      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
