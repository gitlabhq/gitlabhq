import { shallowMount } from '@vue/test-utils';
import WorkItemNotesActivityHeader from '~/work_items/components/notes/work_item_notes_activity_header.vue';
import ActivitySort from '~/work_items/components/notes/activity_sort.vue';
import ActivityFilter from '~/work_items/components/notes/activity_filter.vue';
import { ASC } from '~/notes/constants';
import {
  WORK_ITEM_NOTES_FILTER_ALL_NOTES,
  WORK_ITEM_NOTES_FILTER_ONLY_HISTORY,
} from '~/work_items/constants';

describe('Work Item Note Activity Header', () => {
  let wrapper;

  const findActivityLabelHeading = () => wrapper.find('h3');
  const findActivityFilterDropdown = () => wrapper.findComponent(ActivityFilter);
  const findActivitySortDropdown = () => wrapper.findComponent(ActivitySort);

  const createComponent = ({
    disableActivityFilterSort = false,
    sortOrder = ASC,
    workItemType = 'Task',
    discussionFilter = WORK_ITEM_NOTES_FILTER_ALL_NOTES,
  } = {}) => {
    wrapper = shallowMount(WorkItemNotesActivityHeader, {
      propsData: {
        disableActivityFilterSort,
        sortOrder,
        workItemType,
        discussionFilter,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('Should have the Activity label', () => {
    expect(findActivityLabelHeading().text()).toBe(WorkItemNotesActivityHeader.i18n.activityLabel);
  });

  it('Should have Activity filtering dropdown', () => {
    expect(findActivityFilterDropdown().exists()).toBe(true);
  });

  it('Should have Activity sorting dropdown', () => {
    expect(findActivitySortDropdown().exists()).toBe(true);
  });

  describe('Activity Filter', () => {
    it('emits `changeFilter` when filtering discussions', () => {
      findActivityFilterDropdown().vm.$emit('changeFilter', WORK_ITEM_NOTES_FILTER_ONLY_HISTORY);

      expect(wrapper.emitted('changeFilter')).toEqual([[WORK_ITEM_NOTES_FILTER_ONLY_HISTORY]]);
    });
  });

  describe('Activity Sorting', () => {
    it('emits `changeSort` when sorting discussions/activity', () => {
      findActivitySortDropdown().vm.$emit('changeSort', ASC);

      expect(wrapper.emitted('changeSort')).toEqual([[ASC]]);
    });
  });
});
