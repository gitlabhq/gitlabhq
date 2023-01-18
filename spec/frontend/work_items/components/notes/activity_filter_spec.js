import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ActivityFilter from '~/work_items/components/notes/activity_filter.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { ASC, DESC } from '~/notes/constants';

import { mockTracking } from 'helpers/tracking_helper';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';

describe('Activity Filter', () => {
  let wrapper;

  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findNewestFirstItem = () => wrapper.findByTestId('js-newest-first');

  const createComponent = ({ sortOrder = ASC, loading = false, workItemType = 'Task' } = {}) => {
    wrapper = shallowMountExtended(ActivityFilter, {
      propsData: {
        sortOrder,
        loading,
        workItemType,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('default', () => {
    it('has a dropdown with 2 options', () => {
      expect(findDropdown().exists()).toBe(true);
      expect(findAllDropdownItems()).toHaveLength(ActivityFilter.SORT_OPTIONS.length);
    });

    it('has local storage sync with the correct props', () => {
      expect(findLocalStorageSync().props('asString')).toBe(true);
    });

    it('emits `updateSavedSortOrder` event when update is emitted', async () => {
      findLocalStorageSync().vm.$emit('input', ASC);

      await nextTick();
      expect(wrapper.emitted('updateSavedSortOrder')).toHaveLength(1);
      expect(wrapper.emitted('updateSavedSortOrder')).toEqual([[ASC]]);
    });
  });

  describe('when asc', () => {
    describe('when the dropdown is clicked', () => {
      it('calls the right actions', async () => {
        const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
        findNewestFirstItem().vm.$emit('click');
        await nextTick();

        expect(wrapper.emitted('changeSortOrder')).toHaveLength(1);
        expect(wrapper.emitted('changeSortOrder')).toEqual([[DESC]]);

        expect(trackingSpy).toHaveBeenCalledWith(
          TRACKING_CATEGORY_SHOW,
          'notes_sort_order_changed',
          {
            category: TRACKING_CATEGORY_SHOW,
            label: 'item_track_notes_sorting',
            property: 'type_Task',
          },
        );
      });
    });
  });
});
