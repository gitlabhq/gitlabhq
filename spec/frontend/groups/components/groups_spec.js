import Vue from 'vue';

import { mountExtended } from 'helpers/vue_test_utils_helper';
import GroupFolderComponent from '~/groups/components/group_folder.vue';
import GroupItemComponent from '~/groups/components/group_item.vue';
import PaginationLinks from '~/vue_shared/components/pagination_links.vue';
import GroupsComponent from '~/groups/components/groups.vue';
import eventHub from '~/groups/event_hub';
import { VISIBILITY_LEVEL_PRIVATE } from '~/visibility_level/constants';
import { mockGroups, mockPageInfo } from '../mock_data';

describe('GroupsComponent', () => {
  let wrapper;

  const defaultPropsData = {
    groups: mockGroups,
    pageInfo: mockPageInfo,
    searchEmptyMessage: 'No matching results',
    searchEmpty: false,
  };

  const createComponent = ({ propsData } = {}) => {
    wrapper = mountExtended(GroupsComponent, {
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
      provide: {
        currentGroupVisibility: VISIBILITY_LEVEL_PRIVATE,
      },
    });
  };

  const findPaginationLinks = () => wrapper.findComponent(PaginationLinks);

  beforeEach(async () => {
    Vue.component('GroupFolder', GroupFolderComponent);
    Vue.component('GroupItem', GroupItemComponent);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('methods', () => {
    describe('change', () => {
      it('should emit `fetchPage` event when page is changed via pagination', () => {
        createComponent();

        jest.spyOn(eventHub, '$emit').mockImplementation();

        findPaginationLinks().props('change')(2);

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
    it('should render component template correctly', () => {
      createComponent();

      expect(wrapper.findComponent(GroupFolderComponent).exists()).toBe(true);
      expect(findPaginationLinks().exists()).toBe(true);
      expect(wrapper.findByText(defaultPropsData.searchEmptyMessage).exists()).toBe(false);
    });

    it('should render empty search message when `searchEmpty` is `true`', () => {
      createComponent({ propsData: { searchEmpty: true } });

      expect(wrapper.findByText(defaultPropsData.searchEmptyMessage).exists()).toBe(true);
    });
  });
});
