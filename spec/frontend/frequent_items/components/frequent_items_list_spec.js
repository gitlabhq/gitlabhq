import { mount } from '@vue/test-utils';
import frequentItemsListComponent from '~/frequent_items/components/frequent_items_list.vue';
import frequentItemsListItemComponent from '~/frequent_items/components/frequent_items_list_item.vue';
import { mockFrequentProjects } from '../mock_data';

describe('FrequentItemsListComponent', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(frequentItemsListComponent, {
      propsData: {
        namespace: 'projects',
        items: mockFrequentProjects,
        isFetchFailed: false,
        hasSearchQuery: false,
        matcher: 'lab',
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('isListEmpty', () => {
      it('should return `true` or `false` representing whether if `items` is empty or not with projects', () => {
        createComponent({
          items: [],
        });

        expect(wrapper.vm.isListEmpty).toBe(true);

        wrapper.setProps({
          items: mockFrequentProjects,
        });

        expect(wrapper.vm.isListEmpty).toBe(false);
      });
    });

    describe('fetched item messages', () => {
      it('should return appropriate empty list message based on value of `localStorageFailed` prop with projects', () => {
        createComponent({
          isFetchFailed: true,
        });

        expect(wrapper.vm.listEmptyMessage).toBe(
          'This feature requires browser localStorage support',
        );

        wrapper.setProps({
          isFetchFailed: false,
        });

        expect(wrapper.vm.listEmptyMessage).toBe('Projects you visit often will appear here');
      });
    });

    describe('searched item messages', () => {
      it('should return appropriate empty list message based on value of `searchFailed` prop with projects', () => {
        createComponent({
          hasSearchQuery: true,
          isFetchFailed: true,
        });

        expect(wrapper.vm.listEmptyMessage).toBe('Something went wrong on our end.');

        wrapper.setProps({
          isFetchFailed: false,
        });

        expect(wrapper.vm.listEmptyMessage).toBe('Sorry, no projects matched your search');
      });
    });
  });

  describe('template', () => {
    it('should render component element with list of projects', () => {
      createComponent();

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.classes('frequent-items-list-container')).toBe(true);
        expect(wrapper.findAll({ ref: 'frequentItemsList' })).toHaveLength(1);
        expect(wrapper.findAll(frequentItemsListItemComponent)).toHaveLength(5);
      });
    });

    it('should render component element with empty message', () => {
      createComponent({
        items: [],
      });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.vm.$el.querySelectorAll('li.section-empty')).toHaveLength(1);
        expect(wrapper.findAll(frequentItemsListItemComponent)).toHaveLength(0);
      });
    });
  });
});
