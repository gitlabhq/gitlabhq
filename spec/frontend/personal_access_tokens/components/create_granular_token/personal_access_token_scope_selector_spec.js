import { GlFormGroup, GlFormRadioGroup, GlFormRadio, GlTabs, GlTab, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PersonalAccessTokenScopeSelector from '~/personal_access_tokens/components/create_granular_token/personal_access_token_scope_selector.vue';

describe('PersonalAccessTokenScopeSelector', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(PersonalAccessTokenScopeSelector, {
      propsData: {
        ...props,
      },
      stubs: {
        GlSprintf,
      },
      slots: {
        'namespace-selector': '<div class="namespace-selector-slot">Add group or project</div>',
        'namespace-permissions':
          '<div class="namespace-permissions-slot">Group and project permissions</div>',
        'user-permissions': '<div class="user-permissions-slot">User Permissions</div>',
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
    expect(wrapper.text()).toContain(
      'Add only the minimum resource and permissions  needed for your token. Permissions that exceed your assigned role will have no effect.',
    );
  });

  it('renders tabs', () => {
    expect(findTabs().exists()).toBe(true);
  });

  it('renders group and project tab', () => {
    expect(findGroupTab().exists()).toBe(true);
    expect(findGroupTab().attributes('title')).toBe('Group and project');
  });

  it('renders user tab', () => {
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

  it('renders namespace selector slot in group tab', () => {
    expect(findGroupTab().find('.namespace-selector-slot').exists()).toBe(true);
  });

  it('renders group permissions slot in group tab', () => {
    expect(findGroupTab().find('.namespace-permissions-slot').exists()).toBe(true);
  });

  it('renders user permissions slot in user tab', () => {
    expect(findUserTab().find('.user-permissions-slot').exists()).toBe(true);
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
