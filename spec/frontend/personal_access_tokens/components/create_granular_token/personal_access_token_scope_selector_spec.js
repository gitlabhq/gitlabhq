import { GlFormGroup, GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PersonalAccessTokenScopeSelector from '~/personal_access_tokens/components/create_granular_token/personal_access_token_scope_selector.vue';

describe('PersonalAccessTokenScopeSelector', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(PersonalAccessTokenScopeSelector, {
      propsData: {
        ...props,
      },
      slots: {
        'namespace-selector': '<div class="namespace-selector-slot">Add group or project</div>',
      },
    });
  };

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findRadioButtons = () => wrapper.findAllComponents(GlFormRadio);
  const findErrorMessage = () => wrapper.find('.invalid-feedback');

  beforeEach(() => {
    createComponent();
  });

  it('renders title and description', () => {
    expect(wrapper.text()).toContain('Group and project access');
    expect(wrapper.text()).toContain('Required only if you add group and project resources.');
  });

  it('renders radio buttons for group access options', () => {
    expect(findFormGroup().exists()).toBe(true);
    expect(findFormGroup().attributes('label-for')).toBe('group-access');

    expect(findRadioGroup().exists()).toBe(true);
    expect(findRadioGroup().attributes('id')).toBe('group-access');

    expect(findRadioButtons()).toHaveLength(3);

    expect(findRadioButtons().at(0).attributes('value')).toBe('PERSONAL_PROJECTS');
    expect(findRadioButtons().at(0).text()).toContain('Only my personal projects');

    expect(findRadioButtons().at(1).attributes('value')).toBe('ALL_MEMBERSHIPS');
    expect(findRadioButtons().at(1).text()).toContain(
      "All groups and projects that I'm a member of",
    );

    expect(findRadioButtons().at(2).attributes('value')).toBe('SELECTED_MEMBERSHIPS');
    expect(findRadioButtons().at(2).text()).toContain(
      "Only specific groups or projects that I'm a member of",
    );
  });

  it('renders namespace selector slot in group tab', () => {
    expect(wrapper.find('.namespace-selector-slot').exists()).toBe(true);
  });

  it('displays the selected access option based on the value prop', () => {
    createComponent({ value: 'ALL_MEMBERSHIPS' });

    expect(findRadioGroup().attributes('checked')).toBe('ALL_MEMBERSHIPS');
  });

  it('emits the selected value when the user changes the access option', () => {
    findRadioGroup().vm.$emit('input', 'PERSONAL_PROJECTS');

    expect(wrapper.emitted('input')).toEqual([['PERSONAL_PROJECTS']]);
  });

  describe('error handling', () => {
    it('shows error message when error prop is provided', () => {
      createComponent({ error: 'Set group and project access.' });

      expect(findErrorMessage().exists()).toBe(true);
      expect(findErrorMessage().text()).toBe('Set group and project access.');
    });
  });
});
