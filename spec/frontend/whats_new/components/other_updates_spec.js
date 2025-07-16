import { GlInfiniteScroll } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import OtherUpdates from '~/whats_new/components/other_updates.vue';
import Feature from '~/whats_new/components/feature.vue';
import SkeletonLoader from '~/whats_new/components/skeleton_loader.vue';

const MOCK_DRAWER_BODY_HEIGHT = 42;

describe('OtherUpdates', () => {
  let wrapper;

  const defaultProps = {
    features: [],
    fetching: false,
    drawerBodyHeight: MOCK_DRAWER_BODY_HEIGHT,
    pageInfo: {},
  };

  const createWrapper = (props = {}) => {
    wrapper = mount(OtherUpdates, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findInfiniteScroll = () => wrapper.findComponent(GlInfiniteScroll);
  const findSkeletonLoader = () => wrapper.findComponent(SkeletonLoader);
  const findFeatures = () => wrapper.findAllComponents(Feature);

  describe('with features', () => {
    const mockFeatures = [
      { name: 'Feature 1', documentation_link: 'www.url1.com', release: 3.11 },
      { name: 'Feature 2', documentation_link: 'www.url2.com', release: 3.12 },
    ];

    beforeEach(() => {
      createWrapper({ features: mockFeatures });
    });

    it('renders the "Other updates" title', () => {
      expect(wrapper.find('h5').text()).toBe('Other updates');
    });

    it('renders infinite scroll component', () => {
      const infiniteScroll = findInfiniteScroll();

      expect(infiniteScroll.exists()).toBe(true);
      expect(infiniteScroll.props()).toMatchObject({
        fetchedItems: mockFeatures.length,
        maxListHeight: MOCK_DRAWER_BODY_HEIGHT,
      });
    });

    it('renders feature components for each feature', () => {
      const features = findFeatures();

      expect(features).toHaveLength(mockFeatures.length);
      expect(features.at(0).props('feature')).toEqual(mockFeatures[0]);
      expect(features.at(1).props('feature')).toEqual(mockFeatures[1]);
    });

    it('does not render skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    it('emits bottomReached event when infinite scroll reaches bottom', () => {
      findInfiniteScroll().vm.$emit('bottomReached');

      expect(wrapper.emitted('bottomReached')).toHaveLength(1);
    });

    it('renders infinite scroll with correct props', () => {
      const scroll = findInfiniteScroll();
      const skeletonLoader = findSkeletonLoader();

      expect(skeletonLoader.exists()).toBe(false);

      expect(scroll.props()).toMatchObject({
        fetchedItems: mockFeatures.length,
        maxListHeight: MOCK_DRAWER_BODY_HEIGHT,
      });
    });

    describe('bottomReached with pagination', () => {
      const emitBottomReached = () => findInfiniteScroll().vm.$emit('bottomReached');

      it('emits bottomReached when nextPage exists', () => {
        createWrapper({
          features: mockFeatures,
          pageInfo: { nextPage: 840 },
        });

        emitBottomReached();

        expect(wrapper.emitted('bottomReached')).toHaveLength(1);
        expect(wrapper.emitted('bottomReached')[0]).toEqual([]);
      });

      it('emits bottomReached when nextPage does not exist', () => {
        createWrapper({
          features: mockFeatures,
          pageInfo: { nextPage: null },
        });

        emitBottomReached();

        expect(wrapper.emitted('bottomReached')).toHaveLength(1);
      });
    });
  });

  describe('without features', () => {
    describe('when fetching', () => {
      beforeEach(() => {
        createWrapper({ features: [], fetching: true });
      });

      it('renders skeleton loaders', () => {
        const skeletonLoaders = findSkeletonLoader();

        expect(skeletonLoaders.exists()).toBe(true);
      });

      it('does not render infinite scroll', () => {
        expect(findInfiniteScroll().exists()).toBe(false);
      });

      it('renders skeleton loader when fetching', () => {
        const scroll = findInfiniteScroll();
        const skeletonLoader = findSkeletonLoader();

        expect(scroll.exists()).toBe(false);
        expect(skeletonLoader.exists()).toBe(true);
      });
    });

    describe('when not fetching', () => {
      beforeEach(() => {
        createWrapper({ features: [], fetching: false });
      });

      it('renders infinite scroll with empty features', () => {
        const infiniteScroll = findInfiniteScroll();

        expect(infiniteScroll.exists()).toBe(true);
        expect(infiniteScroll.props('fetchedItems')).toBe(0);
      });

      it('does not render skeleton loaders', () => {
        expect(findSkeletonLoader().exists()).toBe(false);
      });

      it('does not render any feature components', () => {
        expect(findFeatures()).toHaveLength(0);
      });

      it('renders infinite scroll loader when NOT fetching', () => {
        const scroll = findInfiniteScroll();
        const skeletonLoader = findSkeletonLoader();

        expect(scroll.exists()).toBe(true);
        expect(skeletonLoader.exists()).toBe(false);
      });
    });
  });

  describe('props validation', () => {
    it('requires features prop', () => {
      expect(OtherUpdates.props.features.required).toBe(true);
      expect(OtherUpdates.props.features.type).toBe(Array);
    });

    it('requires fetching prop', () => {
      expect(OtherUpdates.props.fetching.required).toBe(true);
      expect(OtherUpdates.props.fetching.type).toBe(Boolean);
    });

    it('requires drawerBodyHeight prop', () => {
      expect(OtherUpdates.props.drawerBodyHeight.required).toBe(true);
      expect(OtherUpdates.props.drawerBodyHeight.type).toBe(Number);
    });
  });
});
