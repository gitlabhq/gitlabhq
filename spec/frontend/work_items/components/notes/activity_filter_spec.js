import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ActivityFilter from '~/work_items/components/notes/activity_filter.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import {
  WORK_ITEM_NOTES_FILTER_ALL_NOTES,
  WORK_ITEM_NOTES_FILTER_ONLY_HISTORY,
  WORK_ITEM_NOTES_FILTER_ONLY_COMMENTS,
  TRACKING_CATEGORY_SHOW,
} from '~/work_items/constants';

import { mockTracking } from 'helpers/tracking_helper';

describe('Work Item Activity/Discussions Filtering', () => {
  let wrapper;

  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findOnlyCommentsItem = () => wrapper.findByTestId('comments-activity');
  const findOnlyHistoryItem = () => wrapper.findByTestId('history-activity');

  const createComponent = ({
    discussionFilter = WORK_ITEM_NOTES_FILTER_ALL_NOTES,
    loading = false,
    workItemType = 'Task',
  } = {}) => {
    wrapper = shallowMountExtended(ActivityFilter, {
      propsData: {
        discussionFilter,
        loading,
        workItemType,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('Default', () => {
    it('has a dropdown with 3 options', () => {
      expect(findDropdown().exists()).toBe(true);
      expect(findAllDropdownItems()).toHaveLength(ActivityFilter.filterOptions.length);
    });

    it('has local storage sync with the correct props', () => {
      expect(findLocalStorageSync().props('asString')).toBe(true);
    });

    it('emits `changeFilter` event when local storage input is emitted', () => {
      findLocalStorageSync().vm.$emit('input', WORK_ITEM_NOTES_FILTER_ONLY_HISTORY);

      expect(wrapper.emitted('changeFilter')).toEqual([[WORK_ITEM_NOTES_FILTER_ONLY_HISTORY]]);
    });
  });

  describe('Changing filter value', () => {
    it.each`
      dropdownLabel      | filterValue                             | dropdownItem
      ${'Comments only'} | ${WORK_ITEM_NOTES_FILTER_ONLY_COMMENTS} | ${findOnlyCommentsItem}
      ${'History only'}  | ${WORK_ITEM_NOTES_FILTER_ONLY_HISTORY}  | ${findOnlyHistoryItem}
    `(
      'when `$dropdownLabel` is clicked it emits `$filterValue` with tracking info',
      ({ dropdownItem, filterValue }) => {
        const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
        dropdownItem().vm.$emit('click');

        expect(wrapper.emitted('changeFilter')).toEqual([[filterValue]]);

        expect(trackingSpy).toHaveBeenCalledWith(
          TRACKING_CATEGORY_SHOW,
          'work_item_notes_filter_changed',
          {
            category: TRACKING_CATEGORY_SHOW,
            label: 'item_track_notes_filtering',
            property: 'type_Task',
          },
        );
      },
    );
  });
});
