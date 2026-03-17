import { GlFormCheckboxGroup, GlFormCheckbox } from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TypeFilter from '~/search/sidebar/components/type_filter/index.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import {
  WORK_ITEM_TYPE_FILTER_PARAM,
  WORK_ITEM_TYPE_FILTER_HEADER,
  LABEL_DEFAULT_CLASSES,
} from '~/search/sidebar/constants';

Vue.use(Vuex);

describe('TypeFilter', () => {
  let wrapper;

  const mockWorkItemTypes = [
    { name: 'issue', label: 'Issue', icon_name: 'work-item-issue' },
    { name: 'task', label: 'Task', icon_name: 'work-item-task' },
    { name: 'epic', label: 'Epic', icon_name: 'work-item-epic' },
    { name: 'objective', label: 'Objective', icon_name: 'work-item-objective' },
  ];

  const mockAggregationBuckets = [
    { key: '1', count: 5, name: 'Task', icon_name: 'issue-type-task', base_type: 'task' },
    { key: '2', count: 12, name: 'Issue', icon_name: 'issue-type-issue', base_type: 'issue' },
    { key: '3', count: 3, name: 'Epic', icon_name: 'issue-type-epic', base_type: 'epic' },
  ];

  const actionSpies = {
    setQuery: jest.fn(),
    fetchAllAggregation: jest.fn(),
  };

  const defaultGetters = {
    queryWorkItemTypeFilters: jest.fn(() => []),
    workItemTypes: jest.fn(() => mockWorkItemTypes),
    workItemTypeAggregationBuckets: jest.fn(() => mockAggregationBuckets),
  };

  const createComponent = (getters = defaultGetters) => {
    const store = new Vuex.Store({
      getters,
      actions: actionSpies,
    });

    wrapper = shallowMountExtended(TypeFilter, {
      store,
    });
  };

  const findFormCheckboxGroup = () => wrapper.findComponent(GlFormCheckboxGroup);
  const findAllCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findAllWorkItemTypeIcons = () => wrapper.findAllComponents(WorkItemTypeIcon);
  const findCheckboxByValue = (value) =>
    findAllCheckboxes().wrappers.find((checkbox) => checkbox.props('value') === value);
  const findHeader = () => wrapper.find('[class*="gl-mb-2"]');
  const findAllCounts = () => wrapper.findAllByTestId('labelCount');

  describe('Renders correctly', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the component', () => {
      expect(wrapper.exists()).toBe(true);
    });

    it('renders the header with correct text', () => {
      expect(findHeader().text()).toBe(WORK_ITEM_TYPE_FILTER_HEADER);
    });

    it('renders form checkbox group', () => {
      expect(findFormCheckboxGroup().exists()).toBe(true);
    });
  });

  describe('Faceted type filtering', () => {
    it('fetches aggregations on created', () => {
      createComponent();
      expect(actionSpies.fetchAllAggregation).toHaveBeenCalled();
    });

    it('only shows types that have aggregation data', () => {
      createComponent();
      expect(findAllCheckboxes()).toHaveLength(3);
      expect(findCheckboxByValue('issue').exists()).toBe(true);
      expect(findCheckboxByValue('task').exists()).toBe(true);
      expect(findCheckboxByValue('epic').exists()).toBe(true);
    });

    it('does not render types without aggregation data', () => {
      createComponent();
      expect(findCheckboxByValue('objective')).toBeUndefined();
    });

    it('falls back to showing all types when aggregation data is empty', () => {
      createComponent({
        ...defaultGetters,
        workItemTypeAggregationBuckets: jest.fn(() => []),
      });
      expect(findAllCheckboxes()).toHaveLength(mockWorkItemTypes.length);
    });

    it('sorts types by count descending', () => {
      createComponent();
      const checkboxValues = findAllCheckboxes().wrappers.map((w) => w.props('value'));
      // issue has count 12, task has count 5, epic has count 3
      expect(checkboxValues).toEqual(['issue', 'task', 'epic']);
    });
  });

  describe('Counts', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays count for each type with aggregation data', () => {
      const counts = findAllCounts();
      expect(counts).toHaveLength(3);
    });

    it('formats the count values', () => {
      const counts = findAllCounts();
      // Sorted by count desc: issue(12), task(5), epic(3)
      expect(counts.at(0).text()).toBe('12');
      expect(counts.at(1).text()).toBe('5');
      expect(counts.at(2).text()).toBe('3');
    });

    it('does not show counts when aggregation data is empty', () => {
      createComponent({
        ...defaultGetters,
        workItemTypeAggregationBuckets: jest.fn(() => []),
      });
      expect(findAllCounts()).toHaveLength(0);
    });

    it('renders a WorkItemTypeIcon for each work item type', () => {
      expect(findAllWorkItemTypeIcons()).toHaveLength(mockAggregationBuckets.length);
    });

    it('passes correct work-item-type prop to WorkItemTypeIcon', () => {
      findAllWorkItemTypeIcons().wrappers.forEach((icon, index) => {
        expect(icon.props('workItemType')).toBe(mockWorkItemTypes[index].name);
      });
    });

    it('passes correct type-icon-name prop to WorkItemTypeIcon', () => {
      findAllWorkItemTypeIcons().wrappers.forEach((icon, index) => {
        expect(icon.props('typeIconName')).toBe(mockWorkItemTypes[index].icon_name);
      });
    });
  });

  describe('User interactions', () => {
    beforeEach(() => {
      createComponent();
    });

    it('updates selection when checkbox is checked', async () => {
      const newSelection = ['issue', 'task'];
      findFormCheckboxGroup().vm.$emit('input', newSelection);

      await nextTick();

      expect(actionSpies.setQuery).toHaveBeenCalledWith(expect.any(Object), {
        key: WORK_ITEM_TYPE_FILTER_PARAM,
        value: newSelection,
      });
    });

    it('calls setQuery with empty array when all selections are cleared', async () => {
      findFormCheckboxGroup().vm.$emit('input', []);

      await nextTick();

      expect(actionSpies.setQuery).toHaveBeenCalledWith(expect.any(Object), {
        key: WORK_ITEM_TYPE_FILTER_PARAM,
        value: [],
      });
    });
  });

  describe('Edge cases', () => {
    it('handles empty workItemTypes array', () => {
      createComponent({
        ...defaultGetters,
        workItemTypes: jest.fn(() => []),
      });

      expect(findAllCheckboxes()).toHaveLength(0);
    });

    it('handles workItemTypes with special characters in names', () => {
      const specialTypes = [
        { name: 'work-item-type', label: 'Work Item Type' },
        { name: 'type_with_underscore', label: 'Type With Underscore' },
      ];

      createComponent({
        ...defaultGetters,
        workItemTypes: jest.fn(() => specialTypes),
        workItemTypeAggregationBuckets: jest.fn(() => []),
      });

      expect(findAllCheckboxes()).toHaveLength(specialTypes.length);
    });
  });

  describe('Component options', () => {
    beforeEach(() => {
      createComponent();
    });

    it('exposes WORK_ITEM_TYPE_FILTER_PARAM as component option', () => {
      expect(wrapper.vm.$options.WORK_ITEM_TYPE_FILTER_PARAM).toBe(WORK_ITEM_TYPE_FILTER_PARAM);
    });

    it('exposes LABEL_DEFAULT_CLASSES as component option', () => {
      expect(wrapper.vm.$options.LABEL_DEFAULT_CLASSES).toBe(LABEL_DEFAULT_CLASSES);
    });
  });

  describe('Accessibility', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders checkboxes with proper test IDs', () => {
      const labels = wrapper.findAllByTestId('label');
      expect(labels).toHaveLength(3);
    });

    it('renders header with semantic structure', () => {
      const header = findHeader();
      expect(header.classes()).toContain('gl-text-sm');
      expect(header.classes()).toContain('gl-font-bold');
    });
  });
});
