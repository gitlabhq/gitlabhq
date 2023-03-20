import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemActivitySortFilter from '~/work_items/components/notes/work_item_activity_sort_filter.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { ASC, DESC } from '~/notes/constants';
import {
  WORK_ITEM_ACTIVITY_SORT_OPTIONS,
  WORK_ITEM_NOTES_SORT_ORDER_KEY,
  WORK_ITEM_NOTES_FILTER_ONLY_COMMENTS,
  WORK_ITEM_NOTES_FILTER_KEY,
  WORK_ITEM_NOTES_FILTER_ALL_NOTES,
  WORK_ITEM_ACTIVITY_FILTER_OPTIONS,
  TRACKING_CATEGORY_SHOW,
} from '~/work_items/constants';

import { mockTracking } from 'helpers/tracking_helper';

describe('Work Item Activity/Discussions Filtering', () => {
  let wrapper;

  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findByDataTestId = (dataTestId) => wrapper.findByTestId(dataTestId);

  const createComponent = ({
    loading = false,
    workItemType = 'Task',
    sortFilterProp = ASC,
    filterOptions = WORK_ITEM_ACTIVITY_SORT_OPTIONS,
    trackingLabel = 'item_track_notes_sorting',
    trackingAction = 'work_item_notes_sort_order_changed',
    filterEvent = 'changeSort',
    defaultSortFilterProp = ASC,
    storageKey = WORK_ITEM_NOTES_SORT_ORDER_KEY,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemActivitySortFilter, {
      propsData: {
        loading,
        workItemType,
        sortFilterProp,
        filterOptions,
        trackingLabel,
        trackingAction,
        filterEvent,
        defaultSortFilterProp,
        storageKey,
      },
    });
  };

  describe.each`
    usedFor        | filterOptions                        | storageKey                        | filterEvent       | newInputOption                          | trackingLabel                 | trackingAction                          | defaultSortFilterProp               | sortFilterProp                      | nonDefaultDataTestId
    ${'Sorting'}   | ${WORK_ITEM_ACTIVITY_SORT_OPTIONS}   | ${WORK_ITEM_NOTES_SORT_ORDER_KEY} | ${'changeSort'}   | ${DESC}                                 | ${'item_track_notes_sorting'} | ${'work_item_notes_sort_order_changed'} | ${ASC}                              | ${ASC}                              | ${'newest-first'}
    ${'Filtering'} | ${WORK_ITEM_ACTIVITY_FILTER_OPTIONS} | ${WORK_ITEM_NOTES_FILTER_KEY}     | ${'changeFilter'} | ${WORK_ITEM_NOTES_FILTER_ONLY_COMMENTS} | ${'item_track_notes_sorting'} | ${'work_item_notes_filter_changed'}     | ${WORK_ITEM_NOTES_FILTER_ALL_NOTES} | ${WORK_ITEM_NOTES_FILTER_ALL_NOTES} | ${'comments-activity'}
  `(
    'When used for $usedFor',
    ({
      filterOptions,
      storageKey,
      filterEvent,
      trackingLabel,
      trackingAction,
      newInputOption,
      defaultSortFilterProp,
      sortFilterProp,
      nonDefaultDataTestId,
    }) => {
      beforeEach(() => {
        createComponent({
          sortFilterProp,
          filterOptions,
          trackingLabel,
          trackingAction,
          filterEvent,
          defaultSortFilterProp,
          storageKey,
        });
      });

      it('has a dropdown with options equal to the length of `filterOptions`', () => {
        expect(findDropdown().exists()).toBe(true);
        expect(findAllDropdownItems()).toHaveLength(filterOptions.length);
      });

      it('has local storage sync with the correct props', () => {
        expect(findLocalStorageSync().props('asString')).toBe(true);
        expect(findLocalStorageSync().props('storageKey')).toBe(storageKey);
      });

      it(`emits ${filterEvent} event when local storage input is emitted`, () => {
        findLocalStorageSync().vm.$emit('input', newInputOption);

        expect(wrapper.emitted(filterEvent)).toEqual([[newInputOption]]);
      });

      it('emits tracking event when the a non default dropdown item is clicked', () => {
        const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
        findByDataTestId(nonDefaultDataTestId).vm.$emit('click');

        expect(trackingSpy).toHaveBeenCalledWith(TRACKING_CATEGORY_SHOW, trackingAction, {
          category: TRACKING_CATEGORY_SHOW,
          label: trackingLabel,
          property: 'type_Task',
        });
      });
    },
  );
});
