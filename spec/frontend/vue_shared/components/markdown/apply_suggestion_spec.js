import { GlDisclosureDropdown, GlFormTextarea, GlButton, GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ApplySuggestionComponent from '~/vue_shared/components/markdown/apply_suggestion.vue';

describe('Apply Suggestion component', () => {
  const propsData = { defaultCommitMessage: 'Apply suggestion', disabled: false };
  let wrapper;

  const createWrapper = (props) => {
    wrapper = shallowMount(ApplySuggestionComponent, { propsData: { ...propsData, ...props } });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findTextArea = () => wrapper.findComponent(GlFormTextarea);
  const findApplyButton = () => wrapper.findComponent(GlButton);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findHelpText = () => wrapper.find('span');

  beforeEach(() => createWrapper());

  describe('initial template', () => {
    it('renders a dropdown with the correct props', () => {
      const dropdown = findDropdown();

      expect(dropdown.exists()).toBe(true);
      expect(dropdown.props('toggleText')).toBe('Apply suggestion');
      expect(dropdown.props('disabled')).toBe(false);
    });

    it('renders a textarea with the correct props', () => {
      const textArea = findTextArea();

      expect(textArea.exists()).toBe(true);
      expect(textArea.attributes('placeholder')).toBe('Apply suggestion');
    });

    it('renders an apply button', () => {
      const applyButton = findApplyButton();

      expect(applyButton.exists()).toBe(true);
      expect(applyButton.text()).toBe('Apply');
    });
  });

  describe('help text', () => {
    describe('when applying a single suggestion', () => {
      it('renders the correct help text', () => {
        expect(findHelpText().text()).toEqual('This also resolves this thread');
      });
    });

    describe('when applying in batch', () => {
      it('renders the correct help text', () => {
        createWrapper({ batchSuggestionsCount: 3 });

        expect(findHelpText().text()).toEqual('This also resolves all related threads');
      });
    });
  });

  describe('disabled', () => {
    it('disables the dropdown', () => {
      createWrapper({ disabled: true });

      expect(findDropdown().props('disabled')).toBe(true);
    });
  });

  describe('error', () => {
    it('displays an error message', () => {
      const errorMessage = 'Error message';
      createWrapper({ errorMessage });

      const alert = findAlert();

      expect(alert.exists()).toBe(true);
      expect(alert.props('variant')).toBe('danger');
      expect(alert.props('dismissible')).toBe(false);
      expect(alert.text()).toBe(errorMessage);
    });
  });

  describe('apply suggestion', () => {
    it('emits an apply event with no message if no message was added', () => {
      findTextArea().vm.$emit('input', null);
      findApplyButton().vm.$emit('click');

      expect(wrapper.emitted('apply')).toEqual([[null]]);
    });

    it('emits an apply event with a user-defined message', () => {
      findTextArea().vm.$emit('input', 'some text');
      findApplyButton().vm.$emit('click');

      expect(wrapper.emitted('apply')).toEqual([['some text']]);
    });
  });
});
