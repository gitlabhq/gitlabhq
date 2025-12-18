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
  const findUserTab = () => wrapper.findAllComponents(GlTab).at(1);

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

    expect(findUserTab().exists()).toBe(true);
    expect(findUserTab().attributes('title')).toBe('User');
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

  describe('events', () => {
    it('emits input event when `User` tab is selected', async () => {
      await findTabs().vm.$emit('input', 1);

      expect(wrapper.emitted('input')[0]).toEqual(['USER']);
    });

    it('emits input event when radio group value changes', async () => {
      await findRadioGroup().vm.$emit('input', 'PERSONAL_PROJECTS');

      expect(wrapper.emitted('input')[0]).toEqual(['PERSONAL_PROJECTS']);
    });

    it('emits input event when `Group` tab is selected', async () => {
      await findRadioGroup().vm.$emit('input', 'SELECTED_MEMBERSHIPS');
      // change to User tab
      await findTabs().vm.$emit('input', 1);
      // back to the Group tab
      await findTabs().vm.$emit('input', 0);

      expect(wrapper.emitted('input')[2]).toEqual(['SELECTED_MEMBERSHIPS']);
    });
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
