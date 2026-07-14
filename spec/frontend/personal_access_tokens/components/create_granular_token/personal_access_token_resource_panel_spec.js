import { GlSearchBoxByType, GlSkeletonLoader, GlSegmentedControl } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PersonalAccessTokenResourcePanel from '~/personal_access_tokens/components/create_granular_token/personal_access_token_resource_panel.vue';
import PersonalAccessTokenResourcesList from '~/personal_access_tokens/components/create_granular_token/personal_access_token_resources_list.vue';
import { mockGroupPermissions } from '../../mock_data';

describe('PersonalAccessTokenResourcePanel', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(PersonalAccessTokenResourcePanel, {
      propsData: {
        activeBoundary: 'namespace',
        permissions: mockGroupPermissions,
        selectedResources: { namespace: [], user: [], instance: [] },
        ...props,
      },
    });
  };

  const findSegmentedControl = () => wrapper.findComponent(GlSegmentedControl);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findResourcesList = () => wrapper.findComponent(PersonalAccessTokenResourcesList);

  beforeEach(() => {
    createComponent();
  });

  describe('rendering', () => {
    it('renders the access label', () => {
      expect(wrapper.text()).toContain('Resource access');
    });

    it('renders the access toggle with an option for each scope and the active boundary', () => {
      expect(findSegmentedControl().props('options')).toEqual([
        { value: 'namespace', text: 'Group and project', count: 0 },
        { value: 'user', text: 'User', count: 0 },
        { value: 'instance', text: 'Global', count: 0 },
      ]);
      expect(findSegmentedControl().props('value')).toBe('namespace');
    });

    it('shows the selected resource count per scope on the access toggle', () => {
      createComponent({
        props: {
          selectedResources: { namespace: ['project', 'repository'], user: ['user'], instance: [] },
        },
      });

      expect(findSegmentedControl().props('options')).toMatchObject([
        { value: 'namespace', count: 2 },
        { value: 'user', count: 1 },
        { value: 'instance', count: 0 },
      ]);
    });

    it('renders the search box', () => {
      expect(findSearchBox().attributes('placeholder')).toBe('Search for resources to add');
    });

    it('renders the resources list for the active boundary', () => {
      expect(findResourcesList().props('scope')).toBe('namespace');
      expect(findResourcesList().props('permissions')).toStrictEqual(mockGroupPermissions);
      expect(findResourcesList().props('isFiltering')).toBe(false);
    });

    it('shows the skeleton loader instead of the resources list while loading', () => {
      createComponent({ props: { isLoading: true } });

      expect(findSkeletonLoader().exists()).toBe(true);
      expect(findResourcesList().exists()).toBe(false);
    });

    it('shows a message when there are no permissions', () => {
      createComponent({ props: { permissions: [] } });

      expect(findResourcesList().exists()).toBe(false);
      expect(wrapper.text()).toContain('No resources found');
    });
  });

  describe('searching', () => {
    it('filters the resources list by description', async () => {
      await findSearchBox().vm.$emit('input', 'Repository');

      expect(findResourcesList().props('permissions')).toStrictEqual([mockGroupPermissions[2]]);
    });

    it('filters the resources list by category', async () => {
      await findSearchBox().vm.$emit('input', 'groups');

      expect(findResourcesList().props('permissions')).toStrictEqual([
        mockGroupPermissions[0],
        mockGroupPermissions[1],
        mockGroupPermissions[3],
      ]);
    });

    it('flags the resources list as filtering while a term is set', async () => {
      await findSearchBox().vm.$emit('input', 'Repository');

      expect(findResourcesList().props('isFiltering')).toBe(true);
    });

    it('shows a message when no resources match', async () => {
      await findSearchBox().vm.$emit('input', 'unknown');

      expect(findResourcesList().exists()).toBe(false);
      expect(wrapper.text()).toContain('No resources found');
    });
  });

  describe('events', () => {
    it('emits `boundary-change` when the access toggle changes', () => {
      findSegmentedControl().vm.$emit('input', 'user');

      expect(wrapper.emitted('boundary-change')).toEqual([['user']]);
    });

    it('emits `resources-input` when the resources list changes', () => {
      findResourcesList().vm.$emit('input', ['project', 'repository']);

      expect(wrapper.emitted('resources-input')).toEqual([[['project', 'repository']]]);
    });
  });
});
