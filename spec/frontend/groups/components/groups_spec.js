import Vue, { nextTick } from 'vue';

import mountComponent from 'helpers/vue_mount_component_helper';
import groupFolderComponent from '~/groups/components/group_folder.vue';
import groupItemComponent from '~/groups/components/group_item.vue';
import groupsComponent from '~/groups/components/groups.vue';
import eventHub from '~/groups/event_hub';
import { mockGroups, mockPageInfo } from '../mock_data';

const createComponent = (searchEmpty = false) => {
  const Component = Vue.extend(groupsComponent);

  return mountComponent(Component, {
    groups: mockGroups,
    pageInfo: mockPageInfo,
    searchEmptyMessage: 'No matching results',
    searchEmpty,
  });
};

describe('GroupsComponent', () => {
  let vm;

  beforeEach(async () => {
    Vue.component('GroupFolder', groupFolderComponent);
    Vue.component('GroupItem', groupItemComponent);

    vm = createComponent();

    await nextTick();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('methods', () => {
    describe('change', () => {
      it('should emit `fetchPage` event when page is changed via pagination', () => {
        jest.spyOn(eventHub, '$emit').mockImplementation();

        vm.change(2);

        expect(eventHub.$emit).toHaveBeenCalledWith('fetchPage', {
          page: 2,
          archived: null,
          filterGroupsBy: null,
          sortBy: null,
        });
      });
    });
  });

  describe('template', () => {
    it('should render component template correctly', async () => {
      await nextTick();
      expect(vm.$el.querySelector('.groups-list-tree-container')).toBeDefined();
      expect(vm.$el.querySelector('.group-list-tree')).toBeDefined();
      expect(vm.$el.querySelector('.gl-pagination')).toBeDefined();
      expect(vm.$el.querySelectorAll('.has-no-search-results').length).toBe(0);
    });

    it('should render empty search message when `searchEmpty` is `true`', async () => {
      vm.searchEmpty = true;
      await nextTick();
      expect(vm.$el.querySelector('.has-no-search-results')).toBeDefined();
    });
  });
});
