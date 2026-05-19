import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import MockAdapter from 'axios-mock-adapter';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import OtherUpdates from '~/whats_new/components/other_updates.vue';
import Feature from '~/whats_new/components/feature.vue';
import SkeletonLoader from '~/whats_new/components/skeleton_loader.vue';
import { useWhatsNew } from '~/whats_new/store';
import { isLoggedIn } from '~/lib/utils/common_utils';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_BAD_REQUEST, HTTP_STATUS_OK } from '~/lib/utils/http_status';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/lib/utils/common_utils');

Vue.use(PiniaVuePlugin);

describe('OtherUpdates', () => {
  let wrapper;
  let pinia;
  let store;

  const defaultProps = {
    features: [],
    fetching: false,
    readArticles: [],
    totalArticlesToRead: 0,
    markAsReadPath: 'path/to/mark_as_read',
    pageInfo: { nextPage: null },
  };

  const createWrapper = (props = {}) => {
    wrapper = mount(OtherUpdates, {
      pinia,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  beforeEach(() => {
    pinia = createTestingPinia();
    store = useWhatsNew();
  });

  const findLoadMoreButton = () => wrapper.find('[data-testid="load-more-button"]');
  const findLoadMoreGlButton = () => {
    const buttons = wrapper.findAllComponents(GlButton);
    return buttons.wrappers.find((w) => w.attributes('data-testid') === 'load-more-button');
  };
  const findSkeletonLoader = () => wrapper.findComponent(SkeletonLoader);
  const findFeatures = () => wrapper.findAllComponents(Feature);

  describe('with features', () => {
    const mockFeatures = [
      { name: 'Feature 1', documentation_link: 'www.url1.com', release: 3.11 },
      { name: 'Feature 2', documentation_link: 'www.url2.com', release: 3.12 },
      { name: 'Feature 3', documentation_link: 'www.url3.com', release: 3.13 },
    ];

    beforeEach(() => {
      createWrapper({ features: mockFeatures });
    });

    it('does not render load more button when no next page', () => {
      const loadMoreButton = findLoadMoreButton();

      expect(loadMoreButton.exists()).toBe(false);
    });

    it('renders feature components for each feature', () => {
      const features = findFeatures();

      expect(features).toHaveLength(mockFeatures.length);
      expect(features.at(0).props('feature')).toEqual(mockFeatures[0]);
      expect(features.at(1).props('feature')).toEqual(mockFeatures[1]);
    });

    it('assigns correct showUnread attributes to each feature', () => {
      createWrapper({ totalArticlesToRead: 2, readArticles: [1], features: mockFeatures });

      const features = findFeatures();

      expect(features).toHaveLength(mockFeatures.length);
      expect(features.at(0).props('showUnread')).toEqual(true);
      expect(features.at(1).props('showUnread')).toEqual(false);
      expect(features.at(2).props('showUnread')).toEqual(true);
    });

    describe('when feature emits mark-article-as-read event', () => {
      let axiosMock;

      beforeEach(() => {
        jest.spyOn(axios, 'post');
        axiosMock = new MockAdapter(axios);
      });

      afterEach(() => {
        axiosMock.restore();
        jest.resetAllMocks();
      });

      it('calls API to save read status and updates readArticles when user logged in', async () => {
        axiosMock.onPost().replyOnce(HTTP_STATUS_OK);
        isLoggedIn.mockReturnValue(true);

        findFeatures().at(1).vm.$emit('mark-article-as-read');

        expect(axios.post).toHaveBeenCalledWith('path/to/mark_as_read', { article_id: 1 });

        await axios.waitForAll();

        expect(store.setReadArticles).toHaveBeenCalledWith([1]);
      });

      it('calls Sentry when api call fails', async () => {
        axiosMock.onPost().replyOnce(HTTP_STATUS_BAD_REQUEST);
        isLoggedIn.mockReturnValue(true);

        findFeatures().at(1).vm.$emit('mark-article-as-read');

        expect(axios.post).toHaveBeenCalledWith('path/to/mark_as_read', { article_id: 1 });

        await axios.waitForAll();

        expect(store.setReadArticles).not.toHaveBeenCalled();
        expect(Sentry.captureException).toHaveBeenCalled();
      });

      it('does not make API call when user is not logged in', () => {
        isLoggedIn.mockReturnValue(false);

        findFeatures().at(1).vm.$emit('mark-article-as-read');

        expect(axios.post).not.toHaveBeenCalled();
      });
    });

    it('does not render skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    describe('load more button', () => {
      it('renders load more button when nextPage exists', () => {
        createWrapper({
          features: mockFeatures,
          pageInfo: { nextPage: 2 },
        });

        const loadMoreButton = findLoadMoreGlButton();

        expect(loadMoreButton.exists()).toBe(true);
        expect(loadMoreButton.props('size')).toBe('small');
        expect(loadMoreButton.props('category')).toBe('tertiary');
        expect(loadMoreButton.props('variant')).toBe('confirm');
        expect(loadMoreButton.text()).toBe('Load more');
      });

      it('does not render load more button when no next page', () => {
        createWrapper({
          features: mockFeatures,
          pageInfo: { nextPage: null },
        });

        expect(findLoadMoreButton().exists()).toBe(false);
      });

      it('shows loading state when fetching', () => {
        createWrapper({
          features: mockFeatures,
          fetching: true,
          pageInfo: { nextPage: 2 },
        });

        const loadMoreButton = findLoadMoreGlButton();

        expect(loadMoreButton.exists()).toBe(true);
        expect(loadMoreButton.props('loading')).toBe(true);
      });

      it('emits load-more event when clicked', () => {
        createWrapper({
          features: mockFeatures,
          pageInfo: { nextPage: 2 },
        });

        findLoadMoreButton().trigger('click');

        expect(wrapper.emitted('load-more')).toHaveLength(1);
      });

      it('moves focus to first new item after loading completes', async () => {
        wrapper = mount(OtherUpdates, {
          pinia,
          propsData: {
            ...defaultProps,
            features: mockFeatures,
            pageInfo: { nextPage: 2 },
          },
          attachTo: document.body,
        });

        findLoadMoreButton().trigger('click');

        const newFeatures = [
          ...mockFeatures,
          { name: 'Feature 4', documentation_link: 'www.url4.com', release: 3.14 },
        ];

        await wrapper.setProps({ features: newFeatures, fetching: true });
        await wrapper.setProps({ fetching: false });
        await nextTick();

        expect(document.activeElement.dataset.testid).toBe('whats-new-article-toggle');
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

      it('does not render load more button', () => {
        expect(findLoadMoreButton().exists()).toBe(false);
      });

      it('renders skeleton loader when fetching', () => {
        const loadMoreButton = findLoadMoreButton();
        const skeletonLoader = findSkeletonLoader();

        expect(loadMoreButton.exists()).toBe(false);
        expect(skeletonLoader.exists()).toBe(true);
      });
    });

    describe('when not fetching', () => {
      beforeEach(() => {
        createWrapper({ features: [], fetching: false });
      });

      it('does not render load more button with empty features', () => {
        const loadMoreButton = findLoadMoreButton();

        expect(loadMoreButton.exists()).toBe(false);
      });

      it('does not render skeleton loaders', () => {
        expect(findSkeletonLoader().exists()).toBe(false);
      });

      it('does not render any feature components', () => {
        expect(findFeatures()).toHaveLength(0);
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

    it('requires pageInfo prop', () => {
      expect(OtherUpdates.props.pageInfo.required).toBe(true);
      expect(OtherUpdates.props.pageInfo.type).toBe(Object);
    });

    it('requires totalArticlesToRead prop', () => {
      expect(OtherUpdates.props.totalArticlesToRead.required).toBe(true);
      expect(OtherUpdates.props.totalArticlesToRead.type).toBe(Number);
    });
  });
});
