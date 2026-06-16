import { GlSorting } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemDisplaySettingsSort from '~/work_items/list/components/work_item_display_settings_sort.vue';

const SORT_OPTIONS = [
  {
    id: 1,
    title: 'Created date',
    sortDirection: {
      ascending: 'CREATED_ASC',
      descending: 'CREATED_DESC',
    },
  },
  {
    id: 2,
    title: 'Updated date',
    sortDirection: {
      ascending: 'UPDATED_ASC',
      descending: 'UPDATED_DESC',
    },
  },
];

describe('WorkItemDisplaySettingsSort', () => {
  let wrapper;

  const findSorting = () => wrapper.findComponent(GlSorting);

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(WorkItemDisplaySettingsSort, {
      propsData: {
        sortOptions: SORT_OPTIONS,
        sortKey: 'CREATED_DESC',
        ...props,
      },
    });
  };

  it('passes sort options transformed to { value, text } for GlSorting', () => {
    createComponent();

    expect(findSorting().props('sortOptions')).toEqual([
      { value: 1, text: 'Created date' },
      { value: 2, text: 'Updated date' },
    ]);
  });

  it('selects the option matching the current descending sort key', () => {
    createComponent({ props: { sortKey: 'UPDATED_DESC' } });

    expect(findSorting().props('sortBy')).toBe(2);
    expect(findSorting().props('isAscending')).toBe(false);
  });

  it('selects the option matching the current ascending sort key', () => {
    createComponent({ props: { sortKey: 'CREATED_ASC' } });

    expect(findSorting().props('sortBy')).toBe(1);
    expect(findSorting().props('isAscending')).toBe(true);
  });

  it('emits sort with the descending key of the new option when sortByChange fires', () => {
    createComponent({ props: { sortKey: 'CREATED_DESC' } });

    findSorting().vm.$emit('sortByChange', 2);

    expect(wrapper.emitted('sort')).toEqual([['UPDATED_DESC']]);
  });

  it('preserves the current direction when changing sort field', () => {
    createComponent({ props: { sortKey: 'CREATED_ASC' } });

    findSorting().vm.$emit('sortByChange', 2);

    expect(wrapper.emitted('sort')).toEqual([['UPDATED_ASC']]);
  });

  it('emits the ascending key when sortDirectionChange fires with true', () => {
    createComponent({ props: { sortKey: 'CREATED_DESC' } });

    findSorting().vm.$emit('sortDirectionChange', true);

    expect(wrapper.emitted('sort')).toEqual([['CREATED_ASC']]);
  });

  it('emits the descending key when sortDirectionChange fires with false', () => {
    createComponent({ props: { sortKey: 'CREATED_ASC' } });

    findSorting().vm.$emit('sortDirectionChange', false);

    expect(wrapper.emitted('sort')).toEqual([['CREATED_DESC']]);
  });
});
