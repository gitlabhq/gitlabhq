import VueApollo from 'vue-apollo';
import Vue from 'vue';
import GetDefaultGroupsQuery from '~/explore/analytics_dashboards/components/get_default_groups.query.graphql';
import GetDefaultGroupQuery from '~/explore/analytics_dashboards/components/get_default_group.query.graphql';
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
  let mockPageGroupHandler;

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

  const createComponent = async (props = {}, provide = {}) => {
    mockHandler = jest.fn().mockResolvedValue({
      data: {
        groups: {
          nodes: props.multiSelect ? [mockGroupA, mockGroupB] : [mockGroupA],
        },
      },
    });

    mockPageGroupHandler = jest.fn().mockResolvedValue({ data: { group: mockGroupB } });

    const apolloProvider = createMockApollo([
      [GetDefaultGroupsQuery, mockHandler],
      [GetDefaultGroupQuery, mockPageGroupHandler],
    ]);

    wrapper = shallowMountExtended(GroupsFilter, {
      apolloProvider,
      propsData: {
        ...props,
      },
      provide: {
        defaultGroupFullPath: null,
        ...provide,
      },
    });

    await waitForPromises();
  };

  const findGroupsDropdownFilter = () => wrapper.findComponent(GroupsDropdownFilter);

  // The location persists between tests, so start each one from a clean URL.
  beforeEach(() => {
    setWindowLocation('/');
  });

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
      expect(mockPageGroupHandler).not.toHaveBeenCalled();
    });

    it('does not emit group-selected', () => {
      expect(wrapper.emitted('group-selected')).toBeUndefined();
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

  describe('when the page provides a group', () => {
    describe('without a groups query param', () => {
      beforeEach(() => {
        return createComponent({}, { defaultGroupFullPath: mockGroupB.fullPath });
      });

      it('loads the group from the page', () => {
        expect(mockPageGroupHandler).toHaveBeenCalledWith({ fullPath: mockGroupB.fullPath });
        expect(mockHandler).not.toHaveBeenCalled();
      });

      it('sets the defaultGroups', () => {
        expect(findGroupsDropdownFilter().props('defaultGroups')).toEqual([mockGroupB]);
      });

      it('emits group-selected so the dashboard picks up the seeded namespace', () => {
        expect(wrapper.emitted('group-selected')).toEqual([[[mockGroupB]]]);
      });
    });

    describe('with a groups query param', () => {
      beforeEach(() => {
        setWindowLocation(`?groups[]=${mockGroupA.id}`);

        return createComponent({}, { defaultGroupFullPath: mockGroupB.fullPath });
      });

      it('prefers the query param over the page group', () => {
        expect(mockHandler).toHaveBeenCalledWith({ ids: ['gid://gitlab/Group/abc'] });
        expect(mockPageGroupHandler).not.toHaveBeenCalled();
      });

      it('sets the defaultGroups', () => {
        expect(findGroupsDropdownFilter().props('defaultGroups')).toEqual([mockGroupA]);
      });
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
