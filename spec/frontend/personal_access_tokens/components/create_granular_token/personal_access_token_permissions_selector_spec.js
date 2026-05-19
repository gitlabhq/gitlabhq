import { GlSearchBoxByType, GlSkeletonLoader, GlTab } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import PersonalAccessTokenPermissionsSelector from '~/personal_access_tokens/components/create_granular_token/personal_access_token_permissions_selector.vue';
import PersonalAccessTokenResourcesList from '~/personal_access_tokens/components/create_granular_token/personal_access_token_resources_list.vue';
import PersonalAccessTokenGranularPermissionsList from '~/personal_access_tokens/components/create_granular_token/personal_access_token_granular_permissions_list.vue';
import getAccessTokenPermissions from '~/personal_access_tokens/graphql/get_access_token_permissions.query.graphql';
import {
  mockAccessTokenPermissionsQueryResponse,
  mockGroupPermissions,
  mockUserPermissions,
} from '../../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

describe('PersonalAccessTokenPermissionsSelector', () => {
  let wrapper;
  let mockApollo;

  const mockQueryHandler = jest.fn().mockResolvedValue(mockAccessTokenPermissionsQueryResponse);

  const createComponent = ({ queryHandler = mockQueryHandler, props = {} } = {}) => {
    mockApollo = createMockApollo([[getAccessTokenPermissions, queryHandler]]);

    wrapper = shallowMountExtended(PersonalAccessTokenPermissionsSelector, {
      apolloProvider: mockApollo,
      propsData: {
        targetBoundaries: ['GROUP', 'PROJECT'],
        ...props,
      },
    });
  };

  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findTab = () => wrapper.findComponent(GlTab);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findResourcesList = () => wrapper.findComponent(PersonalAccessTokenResourcesList);
  const findPermissionsList = () =>
    wrapper.findComponent(PersonalAccessTokenGranularPermissionsList);
  const findErrorMessage = () => wrapper.find('.invalid-feedback');

  beforeEach(() => {
    createComponent();
  });

  describe('rendering', () => {
    it('renders group tab', () => {
      expect(findTab().attributes('title')).toBe('Group and project');
    });

    it('renders user tab', () => {
      createComponent({ props: { targetBoundaries: ['USER'] } });

      expect(findTab().attributes('title')).toBe('User');
    });

    it('renders tab with an initial count', () => {
      expect(findTab().attributes('tabcount')).toBe('0');
    });

    it('renders the search box', () => {
      expect(findSearchBox().exists()).toBe(true);
      expect(findSearchBox().attributes('placeholder')).toBe('Search for resources to add');
    });

    it('shows skeleton loader while loading', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });

    it('shows error message when error prop is provided', () => {
      createComponent({ props: { error: 'At least one permission is required.' } });

      expect(findErrorMessage().exists()).toBe(true);
      expect(findErrorMessage().text()).toBe('At least one permission is required.');
    });
  });

  describe('GraphQL query', () => {
    it('fetches permissions on mount', async () => {
      await waitForPromises();

      expect(mockQueryHandler).toHaveBeenCalled();
    });

    it('shows alert on query error', async () => {
      const error = new Error('GraphQL error');
      const errorHandler = jest.fn().mockRejectedValue(error);

      createComponent({ queryHandler: errorHandler });

      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Error loading permissions. Please refresh page.',
        captureError: true,
        error,
      });
    });
  });

  describe('permissions filtering', () => {
    beforeEach(async () => {
      await waitForPromises();
    });

    it('renders resources list when permissions are loaded', () => {
      expect(findResourcesList().exists()).toBe(true);
      expect(findPermissionsList().exists()).toBe(true);

      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('filters permissions by target boundaries', () => {
      expect(findResourcesList().props('scope')).toBe('namespace');
      expect(findResourcesList().props('permissionsFilteredBySearch')).toStrictEqual(
        mockGroupPermissions,
      );

      expect(findPermissionsList().props('permissions')).toStrictEqual(mockGroupPermissions);
      expect(findPermissionsList().props('scope')).toEqual('namespace');
    });

    it('filters user permissions correctly', async () => {
      createComponent({ props: { targetBoundaries: ['USER'] } });

      await waitForPromises();

      expect(findResourcesList().props('scope')).toBe('user');
      expect(findResourcesList().props('permissionsFilteredBySearch')).toStrictEqual(
        mockUserPermissions,
      );

      expect(findPermissionsList().props('permissions')).toStrictEqual(mockUserPermissions);
      expect(findPermissionsList().props('scope')).toEqual('user');
    });

    it('searches by permission description', async () => {
      await findSearchBox().vm.$emit('input', 'Repository');

      expect(findResourcesList().props('permissionsFilteredBySearch')).toStrictEqual([
        mockGroupPermissions[2],
      ]);

      expect(findPermissionsList().props('permissions')).toStrictEqual(mockGroupPermissions);
    });

    it('searches by permission category', async () => {
      await findSearchBox().vm.$emit('input', 'groups');

      expect(findResourcesList().props('permissionsFilteredBySearch')).toStrictEqual([
        mockGroupPermissions[0],
        mockGroupPermissions[1],
        mockGroupPermissions[3],
      ]);

      expect(findPermissionsList().props('permissions')).toStrictEqual(mockGroupPermissions);
    });

    it('shows message when no matches are found', async () => {
      await findSearchBox().vm.$emit('input', 'unknown');

      expect(wrapper.text()).toContain('No resources found');
    });

    it('displays the selected permissions based on the value prop', () => {
      createComponent({ props: { value: ['read_project', 'write_project'] } });

      expect(findPermissionsList().props('value')).toEqual(['read_project', 'write_project']);
    });
  });

  describe('AI suggestion handling', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    describe('when AI suggests permissions', () => {
      it('selects the suggested permissions and their resources', async () => {
        await wrapper.setProps({ aiPermissions: { suggested: ['read_project'], removed: [] } });

        expect(wrapper.vm.selectedResources).toContain('project');
        expect(wrapper.emitted('input')[0]).toEqual([['read_project']]);
      });

      it('applies permissions when set before the permissions query resolves', async () => {
        createComponent({
          props: { aiPermissions: { suggested: ['read_project'], removed: [] } },
        });

        expect(wrapper.emitted('input')).toBeUndefined();

        await waitForPromises();

        expect(wrapper.emitted('input')[0]).toEqual([['read_project']]);
      });

      it('merges with already selected permissions', async () => {
        await wrapper.setProps({ value: ['write_project'] });
        await wrapper.setProps({ aiPermissions: { suggested: ['read_project'], removed: [] } });

        expect(wrapper.emitted('input')[0]).toEqual([['write_project', 'read_project']]);
      });

      it('merges suggested resources with already selected resources', async () => {
        await findResourcesList().vm.$emit('input', ['repository']);
        await wrapper.setProps({ aiPermissions: { suggested: ['read_project'], removed: [] } });

        expect(wrapper.vm.selectedResources).toContain('repository');
        expect(wrapper.vm.selectedResources).toContain('project');
      });
    });

    describe('when AI removes permissions', () => {
      beforeEach(async () => {
        await findResourcesList().vm.$emit('input', ['project']);
        await findPermissionsList().vm.$emit('input', ['read_project', 'write_project']);
        await wrapper.setProps({ value: ['read_project', 'write_project'] });
      });

      it('removes the specified permissions', async () => {
        await wrapper.setProps({ aiPermissions: { suggested: [], removed: ['read_project'] } });

        expect(wrapper.emitted('input')[1]).toEqual([['write_project']]);
      });

      it('does not remove the resource when all its permissions are cleared', async () => {
        await wrapper.setProps({
          aiPermissions: { suggested: [], removed: ['read_project', 'write_project'] },
        });

        expect(findPermissionsList().props('selectedResources')).toContain('project');
      });
    });
  });

  describe('pre-filling resources from permissions', () => {
    it('selects resources when value prop is provided', async () => {
      await waitForPromises();

      await wrapper.setProps({ value: ['read_project', 'read_repository'] });

      expect(wrapper.vm.selectedResources).toContain('project');
      expect(wrapper.vm.selectedResources).toContain('repository');
    });

    it('merges with already selected resources', async () => {
      await waitForPromises();

      await findResourcesList().vm.$emit('input', ['repository']);
      await wrapper.setProps({ value: ['read_project'] });

      expect(wrapper.vm.selectedResources).toContain('repository');
      expect(wrapper.vm.selectedResources).toContain('project');
    });
  });

  describe('event handling', () => {
    beforeEach(async () => {
      await waitForPromises();
    });

    it('updates selected resources when resources list changes', async () => {
      const selectedResources = ['project', 'repository'];

      await findResourcesList().vm.$emit('input', selectedResources);

      expect(findPermissionsList().props('selectedResources')).toEqual(selectedResources);

      expect(findTab().attributes('tabcount')).toBe('2');
    });

    it('updates tab count when selected resources change', async () => {
      const selectedResources = ['project', 'repository'];

      await findResourcesList().vm.$emit('input', selectedResources);

      expect(findTab().attributes('tabcount')).toBe('2');
    });

    it('emits input event when permissions list changes', async () => {
      await findPermissionsList().vm.$emit('input', ['read_project', 'write_project']);

      expect(wrapper.emitted('input')[0]).toEqual([['read_project', 'write_project']]);

      await findPermissionsList().vm.$emit('input', ['read_repository']);

      expect(wrapper.emitted('input')[1]).toEqual([['read_repository']]);
    });

    it('handles resource uncheck event', async () => {
      await findResourcesList().vm.$emit('input', ['project', 'repository']);

      await findPermissionsList().vm.$emit('input', ['read_project', 'read_repository']);

      expect(wrapper.emitted('input')[0]).toEqual([['read_project', 'read_repository']]);

      await wrapper.setProps({ value: ['read_project', 'read_repository'] });

      // simulate unchecking `project` resource
      await findResourcesList().vm.$emit('input', ['repository']);

      await nextTick();

      expect(wrapper.emitted('input')[1]).toEqual([['read_repository']]);
    });

    it('handles `remove-resource` event', async () => {
      await findResourcesList().vm.$emit('input', ['project', 'repository', 'contributed_project']);

      await findPermissionsList().vm.$emit('input', [
        'read_project',
        'read_repository',
        'read_contributed_project',
      ]);

      expect(wrapper.emitted('input')[0]).toEqual([
        ['read_project', 'read_repository', 'read_contributed_project'],
      ]);

      await wrapper.setProps({
        value: ['read_project', 'read_repository', 'read_contributed_project'],
      });

      // simulate unchecking `project` resource
      await findPermissionsList().vm.$emit('remove-resource', 'project');

      await nextTick();

      expect(wrapper.emitted('input')[1]).toEqual([
        ['read_repository', 'read_contributed_project'],
      ]);
    });
  });
});
