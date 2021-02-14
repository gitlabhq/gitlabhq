import { GlSearchBoxByType } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import searchComponent from '~/frequent_items/components/frequent_items_search_input.vue';
import { createStore } from '~/frequent_items/store';

describe('FrequentItemsSearchInputComponent', () => {
  let wrapper;
  let trackingSpy;
  let vm;
  let store;

  const createComponent = (namespace = 'projects') =>
    shallowMount(searchComponent, {
      store,
      propsData: { namespace },
    });

  const findSearchBoxByType = () => wrapper.find(GlSearchBoxByType);

  beforeEach(() => {
    store = createStore({ dropdownType: 'project' });
    jest.spyOn(store, 'dispatch').mockImplementation(() => {});

    trackingSpy = mockTracking('_category_', document, jest.spyOn);
    trackingSpy.mockImplementation(() => {});

    wrapper = createComponent();

    ({ vm } = wrapper);
  });

  afterEach(() => {
    unmockTracking();
    vm.$destroy();
  });

  describe('template', () => {
    it('should render component element', () => {
      expect(wrapper.classes()).toContain('search-input-container');
      expect(findSearchBoxByType().exists()).toBe(true);
      expect(findSearchBoxByType().attributes()).toMatchObject({
        placeholder: 'Search your projects',
      });
    });
  });

  describe('tracking', () => {
    it('tracks when search query is entered', async () => {
      expect(trackingSpy).not.toHaveBeenCalled();
      expect(store.dispatch).not.toHaveBeenCalled();

      const value = 'my project';

      findSearchBoxByType().vm.$emit('input', value);

      await wrapper.vm.$nextTick();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'type_search_query', {
        label: 'project_dropdown_frequent_items_search_input',
      });
      expect(store.dispatch).toHaveBeenCalledWith('setSearchQuery', value);
    });
  });
});
