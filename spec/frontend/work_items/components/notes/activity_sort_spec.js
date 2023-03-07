import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ActivitySort from '~/work_items/components/notes/activity_sort.vue';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { ASC, DESC } from '~/notes/constants';

import { mockTracking } from 'helpers/tracking_helper';
import { TRACKING_CATEGORY_SHOW } from '~/work_items/constants';

describe('Work Item Activity Sorting', () => {
  let wrapper;

  const findLocalStorageSync = () => wrapper.findComponent(LocalStorageSync);
  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findNewestFirstItem = () => wrapper.findByTestId('newest-first');

  const createComponent = ({ sortOrder = ASC, loading = false, workItemType = 'Task' } = {}) => {
    wrapper = shallowMountExtended(ActivitySort, {
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
      expect(findAllDropdownItems()).toHaveLength(ActivitySort.sortOptions.length);
    });

    it('has local storage sync with the correct props', () => {
      expect(findLocalStorageSync().props('asString')).toBe(true);
    });

    it('emits `changeSort` event when update is emitted', () => {
      findLocalStorageSync().vm.$emit('input', ASC);

      expect(wrapper.emitted('changeSort')).toEqual([[ASC]]);
    });
  });

  describe('when asc', () => {
    describe('when the dropdown is clicked', () => {
      it('calls the right actions', () => {
        const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
        findNewestFirstItem().vm.$emit('click');

        expect(wrapper.emitted('changeSort')).toEqual([[DESC]]);

        expect(trackingSpy).toHaveBeenCalledWith(
          TRACKING_CATEGORY_SHOW,
          'work_item_notes_sort_order_changed',
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
