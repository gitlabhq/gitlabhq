import { GlCollapsibleListbox } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import PersonalAccessTokenGranularPermissionsList from '~/personal_access_tokens/components/create_granular_token/personal_access_token_granular_permissions_list.vue';
import { mockGroupPermissions, mockGroupResources } from '../../mock_data';

describe('PersonalAccessTokenGranularPermissionsList', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = mountExtended(PersonalAccessTokenGranularPermissionsList, {
      propsData: {
        permissions: mockGroupPermissions,
        resources: mockGroupResources,
        ...props,
      },
    });
  };

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findListboxes = () => wrapper.findAllComponents(GlCollapsibleListbox);
  const findListbox = (index) => findListboxes().at(index);

  beforeEach(() => {
    createComponent();
  });

  describe('rendering', () => {
    it('renders crud component with correct title and description', () => {
      expect(findCrudComponent().exists()).toBe(true);
      expect(findCrudComponent().text()).toContain('Group and project permissions');
      expect(findCrudComponent().text()).toContain(
        'Grant permissions only to specific resources in your groups or projects.',
      );
    });

    it('shows empty state when no resources are selected', () => {
      createComponent({ props: { resources: [] } });

      expect(findCrudComponent().text()).toContain('No resources selected');
    });

    it('renders a row for each selected resource', () => {
      expect(findCrudComponent().text()).toContain('project');
      expect(findCrudComponent().text()).toContain('repository');
    });

    it('renders a listbox for each selected resource', () => {
      expect(findListboxes()).toHaveLength(2);

      expect(findListbox(0).props('multiple')).toBe(true);
      expect(findListbox(1).props('multiple')).toBe(true);
    });

    it('renders correct list of permissions for each resource', () => {
      expect(findListbox(0).props('items')).toStrictEqual([
        mockGroupPermissions[0],
        mockGroupPermissions[1],
      ]);

      expect(findListbox(1).props('items')).toStrictEqual([mockGroupPermissions[2]]);
    });

    it('renders correct toggle text', async () => {
      expect(findListbox(0).props('toggleText')).toBe('Select permissions');

      wrapper.setProps({ value: ['read_project', 'write_project'] });
      await nextTick();

      expect(findListbox(0).props('toggleText')).toBe('Read, Write');
    });
  });

  describe('events', () => {
    it('emits input event when listbox selection changes', async () => {
      await findListbox(0).vm.$emit('select', ['read_project', 'write_project']);
      await findListbox(1).vm.$emit('select', ['read_repository']);

      expect(wrapper.emitted('input')).toEqual([
        [['read_project', 'write_project']],
        [['read_repository']],
      ]);
    });
  });
});
