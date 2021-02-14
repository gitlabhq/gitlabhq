import { GlDropdown, GlFormTextarea, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ApplySuggestionComponent from '~/vue_shared/components/markdown/apply_suggestion.vue';

describe('Apply Suggestion component', () => {
  const propsData = { defaultCommitMessage: 'Apply suggestion', disabled: false };
  let wrapper;

  const createWrapper = (props) => {
    wrapper = shallowMount(ApplySuggestionComponent, { propsData: { ...propsData, ...props } });
  };

  const findDropdown = () => wrapper.find(GlDropdown);
  const findTextArea = () => wrapper.find(GlFormTextarea);
  const findApplyButton = () => wrapper.find(GlButton);

  beforeEach(() => createWrapper());

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('initial template', () => {
    it('renders a dropdown with the correct props', () => {
      const dropdown = findDropdown();

      expect(dropdown.exists()).toBe(true);
      expect(dropdown.props('text')).toBe('Apply suggestion');
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

  describe('disabled', () => {
    it('disables the dropdown', () => {
      createWrapper({ disabled: true });

      expect(findDropdown().props('disabled')).toBe(true);
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
