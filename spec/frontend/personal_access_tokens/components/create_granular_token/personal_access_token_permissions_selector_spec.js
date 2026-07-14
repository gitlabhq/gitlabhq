import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import PersonalAccessTokenPermissionsSelector from '~/personal_access_tokens/components/create_granular_token/personal_access_token_permissions_selector.vue';
import PersonalAccessTokenResourcePanel from '~/personal_access_tokens/components/create_granular_token/personal_access_token_resource_panel.vue';
import PersonalAccessTokenGranularPermissionsList from '~/personal_access_tokens/components/create_granular_token/personal_access_token_granular_permissions_list.vue';
import getAccessTokenPermissions from '~/personal_access_tokens/graphql/get_access_token_permissions.query.graphql';
import {
  mockAccessTokenPermissionsQueryResponse,
  mockGroupPermissions,
  mockUserPermissions,
  mockInstancePermissions,
} from '../../mock_data';

jest.mock('~/alert');

Vue.use(VueApollo);

const emptyPermissions = () => ({ namespace: [], user: [], instance: [] });

describe('PersonalAccessTokenPermissionsSelector', () => {
  let wrapper;
  let mockApollo;

  const mockQueryHandler = jest.fn().mockResolvedValue(mockAccessTokenPermissionsQueryResponse);

  const createComponent = ({ queryHandler = mockQueryHandler, props = {} } = {}) => {
    mockApollo = createMockApollo([[getAccessTokenPermissions, queryHandler]]);

    wrapper = shallowMountExtended(PersonalAccessTokenPermissionsSelector, {
      apolloProvider: mockApollo,
      propsData: {
        value: emptyPermissions(),
        ...props,
      },
    });
  };

  const findResourcePanel = () => wrapper.findComponent(PersonalAccessTokenResourcePanel);
  const findPermissionsLists = () =>
    wrapper.findAllComponents(PersonalAccessTokenGranularPermissionsList);
  const findPermissionsList = (index) => findPermissionsLists().at(index);
  const findErrorMessage = () => wrapper.find('.invalid-feedback');

  const setActiveBoundary = (boundary) => findResourcePanel().vm.$emit('boundary-change', boundary);
  const setResources = (resources) => findResourcePanel().vm.$emit('resources-input', resources);

  beforeEach(() => {
    createComponent();
  });

  describe('rendering', () => {
    it('renders the selector title', () => {
      expect(wrapper.text()).toContain('Resource and permission selector');
    });

    it('passes the selected resources for every boundary to the resource panel', () => {
      expect(findResourcePanel().props('selectedResources')).toEqual({
        namespace: [],
        user: [],
        instance: [],
      });
    });

    it('defaults the active boundary to namespace', () => {
      expect(findResourcePanel().props('activeBoundary')).toBe('namespace');
    });

    it('forwards the loading state to the resource panel', () => {
      expect(findResourcePanel().props('isLoading')).toBe(true);
    });

    it('renders a permissions list for each boundary', () => {
      expect(findPermissionsLists()).toHaveLength(3);
      expect(findPermissionsList(0).props('scope')).toBe('namespace');
      expect(findPermissionsList(1).props('scope')).toBe('user');
      expect(findPermissionsList(2).props('scope')).toBe('instance');
    });

    it('passes each boundary its selected permissions from the value prop', () => {
      createComponent({
        props: { value: { namespace: ['read_project'], user: ['read_user'], instance: [] } },
      });

      expect(findPermissionsList(0).props('value')).toEqual(['read_project']);
      expect(findPermissionsList(1).props('value')).toEqual(['read_user']);
      expect(findPermissionsList(2).props('value')).toEqual([]);
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

  describe('permissions bucketing', () => {
    beforeEach(async () => {
      await waitForPromises();
    });

    it('passes each boundary its own permissions to the permissions lists', () => {
      expect(findPermissionsList(0).props('permissions')).toStrictEqual(mockGroupPermissions);
      expect(findPermissionsList(1).props('permissions')).toStrictEqual(mockUserPermissions);
      expect(findPermissionsList(2).props('permissions')).toStrictEqual(mockInstancePermissions);
    });

    it('passes the active boundary permissions to the resource panel', () => {
      expect(findResourcePanel().props('activeBoundary')).toBe('namespace');
      expect(findResourcePanel().props('permissions')).toStrictEqual(mockGroupPermissions);
    });

    it('switches the resource panel permissions when the active boundary changes', async () => {
      await setActiveBoundary('user');

      expect(findResourcePanel().props('activeBoundary')).toBe('user');
      expect(findResourcePanel().props('permissions')).toStrictEqual(mockUserPermissions);

      await setActiveBoundary('instance');

      expect(findResourcePanel().props('activeBoundary')).toBe('instance');
      expect(findResourcePanel().props('permissions')).toStrictEqual(mockInstancePermissions);
    });

    it('passes the updated selected resources to the resource panel', async () => {
      await setResources(['project']);

      expect(findResourcePanel().props('selectedResources')).toEqual({
        namespace: ['project'],
        user: [],
        instance: [],
      });
    });
  });

  describe('event handling', () => {
    beforeEach(async () => {
      await waitForPromises();
    });

    it('updates the active boundary selected resources when the resource panel changes', async () => {
      const selectedResources = ['project', 'repository'];

      await setResources(selectedResources);

      expect(findPermissionsList(0).props('selectedResources')).toEqual(selectedResources);
    });

    it('emits input with the boundary updated when a permissions list changes', async () => {
      await findPermissionsList(0).vm.$emit('input', ['read_project', 'write_project']);

      expect(wrapper.emitted('input')[0]).toEqual([
        { namespace: ['read_project', 'write_project'], user: [], instance: [] },
      ]);
    });

    it('emits input scoped to the boundary of the changed list', async () => {
      await findPermissionsList(2).vm.$emit('input', ['read_compliance_policy_setting']);

      expect(wrapper.emitted('input')[0]).toEqual([
        { namespace: [], user: [], instance: ['read_compliance_policy_setting'] },
      ]);
    });

    it('removes a resource permissions when a resource is unchecked', async () => {
      await setResources(['project']);
      await wrapper.setProps({ value: { namespace: ['read_project'], user: [], instance: [] } });

      await setResources([]);

      expect(wrapper.emitted('input').at(-1)).toEqual([{ namespace: [], user: [], instance: [] }]);
    });

    it('handles `remove-resource` event by clearing that resource permissions', async () => {
      await setResources(['project']);
      await wrapper.setProps({
        value: { namespace: ['read_project', 'write_project'], user: [], instance: [] },
      });

      await findPermissionsList(0).vm.$emit('remove-resource', 'project');

      expect(findPermissionsList(0).props('selectedResources')).not.toContain('project');
      expect(wrapper.emitted('input').at(-1)).toEqual([{ namespace: [], user: [], instance: [] }]);
    });
  });

  describe('AI suggestion handling', () => {
    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    const emptySuggestion = () => ({ namespace: [], user: [], instance: [] });

    describe('when AI suggests permissions', () => {
      it('selects the suggested permissions and their resources in the correct boundary', async () => {
        await wrapper.setProps({
          aiPermissions: {
            suggested: { ...emptySuggestion(), namespace: ['read_project'] },
            removed: emptySuggestion(),
          },
        });

        expect(wrapper.vm.selectedResources.namespace).toContain('project');
        expect(wrapper.emitted('input')[0]).toEqual([
          { namespace: ['read_project'], user: [], instance: [] },
        ]);
      });

      it('applies each boundary bucket to its own section', async () => {
        await wrapper.setProps({
          aiPermissions: {
            suggested: { ...emptySuggestion(), user: ['read_user'] },
            removed: emptySuggestion(),
          },
        });

        expect(wrapper.vm.selectedResources.user).toContain('user');
        expect(wrapper.emitted('input')[0]).toEqual([
          { namespace: [], user: ['read_user'], instance: [] },
        ]);
      });

      it('applies permissions when set before the permissions query resolves', async () => {
        createComponent({
          props: {
            aiPermissions: {
              suggested: { ...emptySuggestion(), namespace: ['read_project'] },
              removed: emptySuggestion(),
            },
          },
        });

        expect(wrapper.emitted('input')).toBeUndefined();

        await waitForPromises();

        expect(wrapper.emitted('input')[0]).toEqual([
          { namespace: ['read_project'], user: [], instance: [] },
        ]);
      });

      it('merges with already selected permissions', async () => {
        await wrapper.setProps({ value: { namespace: ['write_project'], user: [], instance: [] } });
        await wrapper.setProps({
          aiPermissions: {
            suggested: { ...emptySuggestion(), namespace: ['read_project'] },
            removed: emptySuggestion(),
          },
        });

        expect(wrapper.emitted('input').at(-1)).toEqual([
          { namespace: ['write_project', 'read_project'], user: [], instance: [] },
        ]);
      });

      it('merges suggested resources with already selected resources', async () => {
        await setResources(['repository']);
        await wrapper.setProps({
          aiPermissions: {
            suggested: { ...emptySuggestion(), namespace: ['read_project'] },
            removed: emptySuggestion(),
          },
        });

        expect(wrapper.vm.selectedResources.namespace).toEqual(
          expect.arrayContaining(['repository', 'project']),
        );
      });
    });

    describe('when AI removes permissions', () => {
      beforeEach(async () => {
        await wrapper.setProps({
          value: { namespace: ['read_project', 'write_project'], user: [], instance: [] },
        });
      });

      it('removes the specified permissions from their boundary', async () => {
        await wrapper.setProps({
          aiPermissions: {
            suggested: emptySuggestion(),
            removed: { ...emptySuggestion(), namespace: ['read_project'] },
          },
        });

        expect(wrapper.emitted('input').at(-1)).toEqual([
          { namespace: ['write_project'], user: [], instance: [] },
        ]);
      });

      it('does not remove the resource when all its permissions are cleared', async () => {
        await wrapper.setProps({
          aiPermissions: { suggested: [], removed: ['read_project', 'write_project'] },
        });

        expect(wrapper.vm.selectedResources.namespace).toContain('project');
      });
    });

    it('applies both suggestions and removals from a single response without clobbering', async () => {
      await wrapper.setProps({ value: { namespace: ['write_project'], user: [], instance: [] } });

      await wrapper.setProps({
        aiPermissions: {
          suggested: { ...emptySuggestion(), namespace: ['read_project'] },
          removed: { ...emptySuggestion(), namespace: ['write_project'] },
        },
      });

      expect(wrapper.emitted('input').at(-1)).toEqual([
        { namespace: ['read_project'], user: [], instance: [] },
      ]);
    });
  });

  describe('pre-filling resources from permissions', () => {
    it('selects resources for the boundary each permission belongs to', async () => {
      await waitForPromises();

      await wrapper.setProps({
        value: {
          namespace: ['read_project', 'read_repository'],
          user: ['read_user'],
          instance: [],
        },
      });

      expect(wrapper.vm.selectedResources.namespace).toContain('project');
      expect(wrapper.vm.selectedResources.namespace).toContain('repository');
      expect(wrapper.vm.selectedResources.user).toContain('user');
    });

    it('merges with already selected resources', async () => {
      await waitForPromises();
      await setResources(['repository']);

      await wrapper.setProps({
        value: { namespace: ['read_project'], user: [], instance: [] },
      });

      expect(wrapper.vm.selectedResources.namespace).toEqual(
        expect.arrayContaining(['repository', 'project']),
      );
    });
  });

  describe('boundary isolation', () => {
    beforeEach(async () => {
      await waitForPromises();
    });

    it('does not leak a resource into another boundary for a shared permission name', async () => {
      await wrapper.setProps({
        value: { namespace: [], user: ['read_contributed_project'], instance: [] },
      });

      expect(wrapper.vm.selectedResources.user).toContain('project');
      expect(wrapper.vm.selectedResources.namespace).toEqual([]);
    });

    it('applies an AI suggestion only to its boundary for a shared permission name', async () => {
      await wrapper.setProps({
        aiPermissions: {
          suggested: { namespace: [], user: ['read_contributed_project'], instance: [] },
          removed: { namespace: [], user: [], instance: [] },
        },
      });

      expect(wrapper.emitted('input').at(-1)).toEqual([
        { namespace: [], user: ['read_contributed_project'], instance: [] },
      ]);
    });
  });
});
