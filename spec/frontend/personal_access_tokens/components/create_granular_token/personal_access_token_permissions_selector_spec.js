import { GlSearchBoxByType, GlSkeletonLoader } from '@gitlab/ui';
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
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findResourcesList = () => wrapper.findComponent(PersonalAccessTokenResourcesList);
  const findPermissionsList = () =>
    wrapper.findComponent(PersonalAccessTokenGranularPermissionsList);

  beforeEach(() => {
    createComponent();
  });

  describe('rendering', () => {
    it('shows group resource title for group scope', () => {
      expect(wrapper.text()).toContain('Group and project resources');
    });

    it('shows user resource title for user scope', () => {
      createComponent({ props: { targetBoundaries: ['USER'] } });

      expect(wrapper.text()).toBe('User resources');
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

      expect(wrapper.text()).toContain('At least one permission is required.');
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
      expect(findResourcesList().props('permissions')).toStrictEqual(mockGroupPermissions);
      expect(findPermissionsList().props('permissions')).toStrictEqual(mockGroupPermissions);
      expect(findPermissionsList().props('targetBoundaries')).toEqual(['GROUP', 'PROJECT']);
    });

    it('filters user permissions correctly', async () => {
      createComponent({ props: { targetBoundaries: ['USER'] } });

      await waitForPromises();

      expect(findResourcesList().props('permissions')).toStrictEqual(mockUserPermissions);
      expect(findPermissionsList().props('permissions')).toStrictEqual(mockUserPermissions);
      expect(findPermissionsList().props('targetBoundaries')).toEqual(['USER']);
    });

    it('searches by permission description', async () => {
      await findSearchBox().vm.$emit('input', 'Repository');

      expect(findResourcesList().props('permissions')).toStrictEqual([mockGroupPermissions[2]]);
      expect(findPermissionsList().props('permissions')).toStrictEqual(mockGroupPermissions);
    });

    it('searches by permission category', async () => {
      await findSearchBox().vm.$emit('input', 'groups');

      expect(findResourcesList().props('permissions')).toStrictEqual([
        mockGroupPermissions[0],
        mockGroupPermissions[1],
      ]);

      expect(findPermissionsList().props('permissions')).toStrictEqual(mockGroupPermissions);
    });

    it('shows message when no matches are found', async () => {
      await findSearchBox().vm.$emit('input', 'unknown');

      expect(wrapper.text()).toContain('No resources found');
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

      // simulate unchecking `project` resource
      await findResourcesList().vm.$emit('input', ['repository']);

      await nextTick();

      expect(wrapper.emitted('input')[1]).toEqual([['read_repository']]);
    });

    it('handles `remove-resource` event', async () => {
      await findResourcesList().vm.$emit('input', ['project', 'repository']);

      await findPermissionsList().vm.$emit('input', ['read_project', 'read_repository']);

      expect(wrapper.emitted('input')[0]).toEqual([['read_project', 'read_repository']]);

      // simulate unchecking `project` resource
      await findPermissionsList().vm.$emit('remove-resource', 'project');

      await nextTick();

      expect(wrapper.emitted('input')[1]).toEqual([['read_repository']]);
    });
  });
});
