import { GlCollapsibleListbox, GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import PersonalAccessTokenGranularPermissionsList from '~/personal_access_tokens/components/create_granular_token/personal_access_token_granular_permissions_list.vue';
import {
  mockGroupPermissions,
  mockGroupResources,
  mockUserPermissions,
  mockUserResources,
} from '../../mock_data';

describe('PersonalAccessTokenGranularPermissionsList', () => {
  let wrapper;

  const createComponent = ({ props = {}, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(PersonalAccessTokenGranularPermissionsList, {
      propsData: {
        targetBoundaries: ['GROUP', 'PROJECT'],
        permissions: mockGroupPermissions,
        selectedResources: mockGroupResources,
        ...props,
      },
    });
  };

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findCategory = (key) => wrapper.findByTestId(`category-${key}`);
  const findCategoryHeading = (key) => findCategory(key).find('[data-testid="category-heading"]');
  const findResourceName = (key) => findCategory(key).findAll('[data-testid="resource-name"]');
  const findResourceDescription = (key) =>
    findCategory(key).findAll('[data-testid="resource-description"]');
  const findListboxes = () => wrapper.findAllComponents(GlCollapsibleListbox);
  const findListbox = (index) => findListboxes().at(index);
  const findButtons = () => wrapper.findAllComponents(GlButton);
  const findButton = (index) => findButtons().at(index);

  beforeEach(() => {
    createComponent();
  });

  describe('rendering', () => {
    it('renders crud component for group scope', () => {
      createComponent({ mountFn: mountExtended });

      expect(findCrudComponent().exists()).toBe(true);
      expect(findCrudComponent().text()).toContain('Group and project permissions');
      expect(findCrudComponent().text()).toContain(
        'Grant permissions only to specific resources in your groups or projects.',
      );
    });

    it('shows empty state when no resources are selected', () => {
      createComponent({ props: { selectedResources: [] }, mountFn: mountExtended });

      expect(findCrudComponent().text()).toContain('No resources selected');
    });

    it('renders a row for each selected resource with category', () => {
      expect(findCategoryHeading('groups_and_projects').text()).toBe('Groups and projects');

      expect(findResourceName('groups_and_projects').at(0).text()).toBe('Project');
      expect(findResourceDescription('groups_and_projects').at(0).text()).toBe(
        'Project resource description',
      );

      expect(findCategoryHeading('merge_request').text()).toBe('Merge request');
      expect(findResourceName('merge_request').at(0).text()).toBe('Repository');
      expect(findResourceDescription('merge_request').at(0).text()).toBe(
        'Repository resource description',
      );
    });

    it('renders a listbox for each selected resource', () => {
      expect(findListboxes()).toHaveLength(2);

      expect(findListbox(0).props('multiple')).toBe(true);
      expect(findListbox(1).props('multiple')).toBe(true);
    });

    it('renders correct list of permissions for each resource', () => {
      expect(findListbox(0).props('items')).toMatchObject([
        { value: 'read_project', text: 'Read' },
        { value: 'write_project', text: 'Write' },
      ]);

      expect(findListbox(1).props('items')).toMatchObject([
        { value: 'read_repository', text: 'Read' },
      ]);
    });

    it('renders resources while preserving selection order', () => {
      createComponent({ props: { selectedResources: ['repository', 'project'] } });

      expect(findListbox(0).props('items')).toMatchObject([
        { value: 'read_repository', text: 'Read' },
      ]);

      expect(findListbox(1).props('items')).toMatchObject([
        { value: 'read_project', text: 'Read' },
        { value: 'write_project', text: 'Write' },
      ]);
    });

    it('renders correct toggle text', async () => {
      expect(findListbox(0).props('toggleText')).toBe('Select permissions');

      wrapper.setProps({ value: ['read_project', 'write_project'] });
      await nextTick();

      expect(findListbox(0).props('toggleText')).toBe('Read, Write');
    });

    it('renders button to remove resource', () => {
      expect(findButtons()).toHaveLength(2);
      expect(findButton(0).props('icon')).toBe('close');
    });

    describe('for user scope', () => {
      beforeEach(() => {
        createComponent({
          props: {
            targetBoundaries: ['USER'],
            permissions: mockUserPermissions,
            selectedResources: mockUserResources,
          },
          mountFn: mountExtended,
        });
      });

      it('renders crud component for user scope', () => {
        expect(findCrudComponent().exists()).toBe(true);
        expect(findCrudComponent().text()).toContain('User permissions');
        expect(findCrudComponent().text()).toContain(
          'Grant permissions to resources in your GitLab user account.',
        );
      });

      it('renders correct list of permissions for each resource', () => {
        expect(findListbox(0).props('items')).toMatchObject([{ value: 'read_user', text: 'Read' }]);

        expect(findListbox(1).props('items')).toMatchObject([
          { value: 'read_contributed_project', text: 'Read contributed' },
        ]);
      });
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

    it('emits `resource-removed` event when button is clicked', async () => {
      await findButton(0).vm.$emit('click');

      expect(wrapper.emitted('remove-resource')).toEqual([['project']]);
    });
  });
});
