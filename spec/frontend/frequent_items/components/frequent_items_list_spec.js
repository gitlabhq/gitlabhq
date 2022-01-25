import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import Vuex from 'vuex';
import frequentItemsListComponent from '~/frequent_items/components/frequent_items_list.vue';
import frequentItemsListItemComponent from '~/frequent_items/components/frequent_items_list_item.vue';
import { createStore } from '~/frequent_items/store';
import { mockFrequentProjects } from '../mock_data';

Vue.use(Vuex);

describe('FrequentItemsListComponent', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(frequentItemsListComponent, {
      store: createStore(),
      propsData: {
        namespace: 'projects',
        items: mockFrequentProjects,
        isFetchFailed: false,
        hasSearchQuery: false,
        matcher: 'lab',
        ...props,
      },
      provide: {
        vuexModule: 'frequentProjects',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('isListEmpty', () => {
      it('should return `true` or `false` representing whether if `items` is empty or not with projects', async () => {
        createComponent({
          items: [],
        });

        expect(wrapper.vm.isListEmpty).toBe(true);

        wrapper.setProps({
          items: mockFrequentProjects,
        });
        await nextTick();

        expect(wrapper.vm.isListEmpty).toBe(false);
      });
    });

    describe('fetched item messages', () => {
      it('should return appropriate empty list message based on value of `localStorageFailed` prop with projects', async () => {
        createComponent({
          isFetchFailed: true,
        });

        expect(wrapper.vm.listEmptyMessage).toBe(
          'This feature requires browser localStorage support',
        );

        wrapper.setProps({
          isFetchFailed: false,
        });
        await nextTick();

        expect(wrapper.vm.listEmptyMessage).toBe('Projects you visit often will appear here');
      });
    });

    describe('searched item messages', () => {
      it('should return appropriate empty list message based on value of `searchFailed` prop with projects', async () => {
        createComponent({
          hasSearchQuery: true,
          isFetchFailed: true,
        });

        expect(wrapper.vm.listEmptyMessage).toBe('Something went wrong on our end.');

        wrapper.setProps({
          isFetchFailed: false,
        });
        await nextTick();

        expect(wrapper.vm.listEmptyMessage).toBe('Sorry, no projects matched your search');
      });
    });
  });

  describe('template', () => {
    it('should render component element with list of projects', async () => {
      createComponent();

      await nextTick();
      expect(wrapper.classes('frequent-items-list-container')).toBe(true);
      expect(wrapper.findAll({ ref: 'frequentItemsList' })).toHaveLength(1);
      expect(wrapper.findAll(frequentItemsListItemComponent)).toHaveLength(5);
    });

    it('should render component element with empty message', async () => {
      createComponent({
        items: [],
      });

      await nextTick();
      expect(wrapper.vm.$el.querySelectorAll('li.section-empty')).toHaveLength(1);
      expect(wrapper.findAll(frequentItemsListItemComponent)).toHaveLength(0);
    });
  });
});
