import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import AddIssuableResourceLinkForm from '~/linked_resources/components/add_issuable_resource_link_form.vue';

describe('AddIssuableResourceLinkForm', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = mountExtended(AddIssuableResourceLinkForm);
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  const findAddButton = () => wrapper.findByTestId('add-button');
  const findCancelButton = () => wrapper.findByText('Cancel');
  const findLinkTextInput = () => wrapper.findByTestId('link-text-input');
  const findLinkValueInput = () => wrapper.findByTestId('link-value-input');

  const cancelForm = async () => {
    await findCancelButton().trigger('click');
  };

  describe('cancel form button', () => {
    const closeFormEvent = { 'add-issuable-resource-link-form-cancel': [[]] };

    beforeEach(() => {
      mountComponent();
    });

    it('should close the form on cancel', async () => {
      await cancelForm();

      expect(wrapper.emitted()).toEqual(closeFormEvent);
    });

    it('keeps the button disabled without input', () => {
      expect(findAddButton().props('disabled')).toBe(true);
    });

    it('keeps the button disabled with only text input', async () => {
      findLinkTextInput().setValue('link text');

      await nextTick();

      expect(findAddButton().props('disabled')).toBe(true);
    });

    it('enables add button when link input is provided', async () => {
      findLinkTextInput().setValue('link text');
      findLinkValueInput().setValue('https://foo.example.com');

      await nextTick();

      expect(findAddButton().props('disabled')).toBe(false);
    });
  });
});
