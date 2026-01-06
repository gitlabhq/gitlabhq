import { GlFormGroup, GlFormRadioGroup, GlFormRadio, GlTabs, GlTab } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PersonalAccessTokenScopeSelector from '~/personal_access_tokens/components/create_granular_token/personal_access_token_scope_selector.vue';

describe('PersonalAccessTokenScopeSelector', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(PersonalAccessTokenScopeSelector, {
      propsData: {
        ...props,
      },
    });
  };

  const findFormGroup = () => wrapper.findComponent(GlFormGroup);
  const findRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findRadioButtons = () => wrapper.findAllComponents(GlFormRadio);
  const findTabs = () => wrapper.findComponent(GlTabs);
  const findGroupTab = () => wrapper.findAllComponents(GlTab).at(0);

  beforeEach(() => {
    createComponent();
  });

  it('renders the scope selector with title', () => {
    expect(wrapper.text()).toContain('Define scope');
  });

  it('renders tabs for group/project and user scopes', () => {
    expect(findTabs().exists()).toBe(true);

    expect(findGroupTab().exists()).toBe(true);
    expect(findGroupTab().attributes('title')).toBe('Group and project');
  });

  it('renders form group for group access options', () => {
    expect(findFormGroup().exists()).toBe(true);
    expect(findFormGroup().attributes('label')).toBe('Group and project access');
    expect(findFormGroup().attributes('label-for')).toBe('group-access');
  });

  it('renders radio buttons for group access options', () => {
    expect(findRadioGroup().exists()).toBe(true);
    expect(findRadioGroup().attributes('id')).toBe('group-access');

    expect(findRadioButtons()).toHaveLength(3);

    expect(findRadioButtons().at(0).attributes('value')).toBe('PERSONAL_PROJECTS');
    expect(findRadioButtons().at(0).text()).toContain('Only personal projects');

    expect(findRadioButtons().at(1).attributes('value')).toBe('ALL_MEMBERSHIPS');
    expect(findRadioButtons().at(1).text()).toContain(
      "All groups and projects that I'm a member of",
    );

    expect(findRadioButtons().at(2).attributes('value')).toBe('SELECTED_MEMBERSHIPS');
    expect(findRadioButtons().at(2).text()).toContain(
      "Only specific groups or projects that I'm a member of",
    );
  });

  describe('error handling', () => {
    it('passes error state to form group', () => {
      createComponent({ error: 'At least one scope is required.' });

      expect(findFormGroup().attributes('invalid-feedback')).toBe(
        'At least one scope is required.',
      );
    });
  });
});
