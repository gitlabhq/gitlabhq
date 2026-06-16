import VueApollo from 'vue-apollo';
import Vue from 'vue';
import GetDefaultGroupsQuery from '~/explore/analytics_dashboards/components/get_default_groups.query.graphql';
import GroupsFilter from '~/explore/analytics_dashboards/components/groups_filter.vue';
import GroupsDropdownFilter from '~/analytics/shared/components/groups_dropdown_filter.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);

describe('GroupsFilter', () => {
  let wrapper;
  let mockHandler;

  const mockGroupA = {
    id: 'abc',
    fullPath: 'a-fake-group',
    name: 'A fake group',
    avatarUrl: 'avatarUrl',
  };

  const mockGroupB = {
    id: 'def',
    fullPath: 'b/fake-group',
    name: 'B fake subgroup',
    avatarUrl: 'avatarUrl',
  };

  const createComponent = async (props = {}) => {
    mockHandler = jest.fn().mockResolvedValue({
      data: {
        groups: {
          nodes: props.multiSelect ? [mockGroupA, mockGroupB] : [mockGroupA],
        },
      },
    });

    const apolloProvider = createMockApollo([[GetDefaultGroupsQuery, mockHandler]]);

    wrapper = shallowMountExtended(GroupsFilter, {
      apolloProvider,
      propsData: {
        ...props,
      },
    });

    await waitForPromises();
  };

  const findGroupsDropdownFilter = () => wrapper.findComponent(GroupsDropdownFilter);

  describe('default', () => {
    beforeEach(() => {
      return createComponent();
    });

    it('renders GroupsDropdownFilter component', () => {
      expect(findGroupsDropdownFilter().exists()).toBe(true);
    });

    it('passes correct props to GroupsDropdownFilter', () => {
      expect(findGroupsDropdownFilter().props()).toMatchObject({
        toggleClasses: 'gl-max-w-26',
        queryParams: {
          first: 50,
          includeSubgroups: true,
        },
        multiSelect: false,
      });
    });

    it('does not set default groups', () => {
      expect(findGroupsDropdownFilter().props('defaultGroups')).toEqual([]);
    });

    it('does not load the defaultGroups', () => {
      expect(findGroupsDropdownFilter().props('loadingDefaultGroups')).toBe(false);
      expect(mockHandler).not.toHaveBeenCalled();
    });
  });

  describe('when groups[] query param is set', () => {
    beforeEach(() => {
      setWindowLocation(`?groups[]=${mockGroupA.id}&groups[]=${mockGroupB.id}`);
    });

    describe('while loading', () => {
      beforeEach(() => {
        createComponent();
      });

      it('sets loadingDefaultGroups to true', () => {
        expect(findGroupsDropdownFilter().props('loadingDefaultGroups')).toBe(true);
      });
    });

    describe('when `multiSelect` prop is disabled', () => {
      beforeEach(() => {
        return createComponent();
      });

      it('loads the first default group', () => {
        expect(mockHandler).toHaveBeenCalledWith({ ids: ['gid://gitlab/Group/abc'] });
      });

      it('sets the defaultGroups', () => {
        expect(findGroupsDropdownFilter().props('defaultGroups')).toEqual([mockGroupA]);
      });

      it('sets loadingDefaultGroups to false', () => {
        expect(findGroupsDropdownFilter().props('loadingDefaultGroups')).toBe(false);
      });
    });

    describe('when `multiSelect` prop is enabled', () => {
      beforeEach(() => {
        return createComponent({ multiSelect: true });
      });

      it('loads the default groups', () => {
        expect(mockHandler).toHaveBeenCalledWith({
          ids: ['gid://gitlab/Group/abc', 'gid://gitlab/Group/def'],
        });
      });

      it('sets the defaultGroups', () => {
        expect(findGroupsDropdownFilter().props('defaultGroups')).toEqual([mockGroupA, mockGroupB]);
      });
    });
  });

  describe('when groups query param is set without the `[]` suffix', () => {
    beforeEach(() => {
      setWindowLocation(`?groups=${mockGroupA.id}`);
      return createComponent();
    });

    it('loads the default group', () => {
      expect(mockHandler).toHaveBeenCalledWith({ ids: ['gid://gitlab/Group/abc'] });
    });
  });

  describe('onGroupsSelected', () => {
    beforeEach(() => {
      return createComponent();
    });

    it('emits group-selected event with correct values when a group is selected', () => {
      expect(wrapper.emitted('group-selected')).toBeUndefined();

      const selectedGroup = {
        fullPath: 'group/subgroup',
        id: '123',
      };
      findGroupsDropdownFilter().vm.$emit('selected', [selectedGroup]);

      expect(wrapper.emitted('group-selected')).toEqual([[[selectedGroup]]]);
    });

    it('emits group-selected event with empty list when no group is selected (e.g. selection cleared)', () => {
      findGroupsDropdownFilter().vm.$emit('selected', []);

      expect(wrapper.emitted('group-selected')).toEqual([[[]]]);
    });
  });

  describe('when `multi-select=true`', () => {
    beforeEach(() => {
      return createComponent({ multiSelect: true });
    });

    it('passes correct props to GroupsDropdownFilter', () => {
      expect(findGroupsDropdownFilter().props()).toMatchObject({ multiSelect: true });
    });
  });
});
