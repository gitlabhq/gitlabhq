import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { ASC } from '~/notes/constants';
import WorkItemNotesActivityHeader from '~/work_items/components/notes/work_item_notes_activity_header.vue';
import { WORK_ITEM_NOTES_FILTER_ONLY_HISTORY } from '~/work_items/constants';

describe('WorkItemNotesActivityHeader component', () => {
  let wrapper;

  const findActivityLabelH2Heading = () => wrapper.find('h2');
  const findActivityLabelH3Heading = () => wrapper.find('h3');
  const findActivityFilterDropdown = () => wrapper.findByTestId('work-item-filter');
  const findActivitySortDropdown = () => wrapper.findByTestId('work-item-sort');

  const createComponent = ({ useH2 = false } = {}) => {
    wrapper = shallowMountExtended(WorkItemNotesActivityHeader, {
      propsData: {
        disableActivityFilterSort: false,
        useH2,
        workItemId: 'gid://gitlab/WorkItem/123',
        workItemType: 'Task',
      },
    });
  };

  it('renders Activity heading', () => {
    createComponent();

    expect(findActivityLabelH3Heading().text()).toBe('Activity');
  });

  it('renders an h3 heading by default', () => {
    createComponent();

    expect(findActivityLabelH3Heading().exists()).toBe(true);
    expect(findActivityLabelH2Heading().exists()).toBe(false);
  });

  it('renders an h2 heading when useH2=true', () => {
    createComponent({ useH2: true });

    expect(findActivityLabelH2Heading().exists()).toBe(true);
    expect(findActivityLabelH3Heading().exists()).toBe(false);
  });

  it('Should have Activity filtering dropdown', () => {
    createComponent();

    expect(findActivityFilterDropdown().exists()).toBe(true);
  });

  it('Should have Activity sorting dropdown', () => {
    createComponent();

    expect(findActivitySortDropdown().exists()).toBe(true);
  });

  describe('Activity Filter', () => {
    it('emits `changeFilter` when filtering discussions', () => {
      createComponent();

      findActivityFilterDropdown().vm.$emit('select', WORK_ITEM_NOTES_FILTER_ONLY_HISTORY);

      expect(wrapper.emitted('changeFilter')).toEqual([[WORK_ITEM_NOTES_FILTER_ONLY_HISTORY]]);
    });
  });

  describe('Activity Sorting', () => {
    it('emits `changeSort` when sorting discussions/activity', () => {
      createComponent();

      findActivitySortDropdown().vm.$emit('select', ASC);

      expect(wrapper.emitted('changeSort')).toEqual([[ASC]]);
    });
  });
});
