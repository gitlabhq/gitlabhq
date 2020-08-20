import Vuex from 'vuex';
import { GlSearchBoxByClick } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import PackagesFilter from '~/packages/list/components/packages_filter.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('packages_filter', () => {
  let wrapper;
  let store;

  const findGlSearchBox = () => wrapper.find(GlSearchBoxByClick);

  const mountComponent = () => {
    store = new Vuex.Store();
    store.dispatch = jest.fn();

    wrapper = shallowMount(PackagesFilter, {
      localVue,
      store,
    });
  };

  beforeEach(mountComponent);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('emits events', () => {
    it('sets the filter value in the store on input', () => {
      const searchString = 'foo';
      findGlSearchBox().vm.$emit('input', searchString);

      expect(store.dispatch).toHaveBeenCalledWith('setFilter', searchString);
    });

    it('emits the filter event when search box is submitted', () => {
      findGlSearchBox().vm.$emit('submit');

      expect(wrapper.emitted('filter')).toBeTruthy();
    });
  });
});
