import { shallowMount } from '@vue/test-utils';
import GlobalSearchDefaultItems from '~/super_sidebar/components/global_search/components/global_search_default_items.vue';
import GlobalSearchDefaultPlaces from '~/super_sidebar/components/global_search/components/global_search_default_places.vue';
import GlobalSearchDefaultIssuables from '~/super_sidebar/components/global_search/components/global_search_default_issuables.vue';

describe('GlobalSearchDefaultItems', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(GlobalSearchDefaultItems);
  };

  const findPlaces = () => wrapper.findComponent(GlobalSearchDefaultPlaces);
  const findIssuables = () => wrapper.findComponent(GlobalSearchDefaultIssuables);
  const receivedAttrs = (wrapperInstance) => ({
    // See https://github.com/vuejs/test-utils/issues/2151.
    ...wrapperInstance.vm.$attrs,
  });

  beforeEach(() => {
    createComponent();
  });

  describe('all child components can render', () => {
    it('renders the components', () => {
      expect(findPlaces().exists()).toBe(true);
      expect(findIssuables().exists()).toBe(true);
    });

    it('sets the expected props on first component', () => {
      const places = findPlaces();
      expect(receivedAttrs(places)).toEqual({});
      expect(places.classes()).toEqual([]);
    });

    it('sets the expected props on second component', () => {
      const issuables = findIssuables();
      expect(receivedAttrs(issuables)).toEqual({ bordered: true });
      expect(issuables.classes()).toEqual(['gl-mt-3']);
    });
  });

  describe('when a child component emits nothing-to-render', () => {
    beforeEach(() => {
      findPlaces().vm.$emit('nothing-to-render');
    });

    it('does not render the component', () => {
      expect(findPlaces().exists()).toBe(false);
      expect(findIssuables().exists()).toBe(true);
    });

    it('sets the expected props on first component', () => {
      const issuables = findIssuables();
      expect(receivedAttrs(issuables)).toEqual({});
      expect(issuables.classes()).toEqual([]);
    });
  });
});
