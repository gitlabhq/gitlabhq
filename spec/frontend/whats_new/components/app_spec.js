import { GlDrawer, GlInfiniteScroll } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mockTracking, unmockTracking, triggerEvent } from 'helpers/tracking_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import App from '~/whats_new/components/app.vue';
import SkeletonLoader from '~/whats_new/components/skeleton_loader.vue';
import { getDrawerBodyHeight } from '~/whats_new/utils/get_drawer_body_height';

const MOCK_DRAWER_BODY_HEIGHT = 42;

jest.mock('~/whats_new/utils/get_drawer_body_height', () => ({
  getDrawerBodyHeight: jest.fn().mockImplementation(() => MOCK_DRAWER_BODY_HEIGHT),
}));

Vue.use(Vuex);

describe('App', () => {
  let wrapper;
  let store;
  let actions;
  let state;
  let trackingSpy;

  const buildProps = () => ({
    versionDigest: 'version-digest',
  });

  const buildWrapper = () => {
    actions = {
      openDrawer: jest.fn(),
      closeDrawer: jest.fn(),
      fetchItems: jest.fn(),
      setDrawerBodyHeight: jest.fn(),
    };

    state = {
      open: true,
      features: [],
      drawerBodyHeight: null,
      fetching: false,
    };

    store = new Vuex.Store({
      actions,
      state,
    });

    wrapper = mount(App, {
      store,
      propsData: buildProps(),
      directives: {
        GlResizeObserver: createMockDirective('gl-resize-observer'),
      },
      attachTo: document.body,
    });
  };

  const getDrawer = () => wrapper.findComponent(GlDrawer);
  const findInfiniteScroll = () => wrapper.findComponent(GlInfiniteScroll);
  const findSkeletonLoader = () => wrapper.findComponent(SkeletonLoader);

  const setup = async (features, fetching) => {
    document.body.dataset.page = 'test-page';
    document.body.dataset.namespaceId = 'namespace-840';

    trackingSpy = mockTracking('_category_', null, jest.spyOn);
    buildWrapper();

    store.state.features = features;
    store.state.fetching = fetching;
    store.state.drawerBodyHeight = MOCK_DRAWER_BODY_HEIGHT;
    await nextTick();
  };

  afterEach(() => {
    unmockTracking();
  });

  describe('gitlab.com', () => {
    describe('with features', () => {
      beforeEach(() => {
        setup(
          [{ name: 'Whats New Drawer', documentation_link: 'www.url.com', release: 3.11 }],
          false,
        );
      });

      const getBackdrop = () => wrapper.find('.whats-new-modal-backdrop');

      it('contains a drawer', () => {
        expect(getDrawer().exists()).toBe(true);
      });

      it('dispatches openDrawer and tracking calls when mounted', () => {
        expect(actions.openDrawer).toHaveBeenCalledWith(expect.any(Object), 'version-digest');
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_whats_new_drawer', {
          label: 'namespace_id',
          property: 'navigation_top',
          value: 'namespace-840',
        });
      });

      it('dispatches closeDrawer when clicking close', () => {
        getDrawer().vm.$emit('close');
        expect(actions.closeDrawer).toHaveBeenCalled();
      });

      it('dispatches closeDrawer when clicking the backdrop', () => {
        getBackdrop().trigger('click');
        expect(actions.closeDrawer).toHaveBeenCalled();
      });

      it.each([true, false])('passes open property', async (openState) => {
        store.state.open = openState;

        await nextTick();

        expect(getDrawer().props('open')).toBe(openState);
      });

      it('renders features when provided via ajax', () => {
        expect(actions.fetchItems).toHaveBeenCalled();
        expect(wrapper.find('[data-testid="feature-name"]').text()).toBe('Whats New Drawer');
      });

      it('send an event when feature item is clicked', () => {
        trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);

        const link = wrapper.find('[data-testid="whats-new-item-link"]');
        triggerEvent(link.element);

        expect(trackingSpy.mock.calls[1]).toMatchObject([
          '_category_',
          'click_whats_new_item',
          {
            label: 'Whats New Drawer',
            property: 'www.url.com',
          },
        ]);
      });

      it('renders infinite scroll', () => {
        const scroll = findInfiniteScroll();
        const skeletonLoader = findSkeletonLoader();

        expect(skeletonLoader.exists()).toBe(false);

        expect(scroll.props()).toMatchObject({
          fetchedItems: store.state.features.length,
          maxListHeight: MOCK_DRAWER_BODY_HEIGHT,
        });
      });

      describe('bottomReached', () => {
        const emitBottomReached = () => findInfiniteScroll().vm.$emit('bottomReached');

        beforeEach(() => {
          actions.fetchItems.mockClear();
        });

        it('when nextPage exists it calls fetchItems', () => {
          store.state.pageInfo = { nextPage: 840 };
          emitBottomReached();

          expect(actions.fetchItems).toHaveBeenCalledWith(expect.anything(), {
            page: 840,
            versionDigest: 'version-digest',
          });
        });

        it('when nextPage does not exist it does not call fetchItems', () => {
          store.state.pageInfo = { nextPage: null };
          emitBottomReached();

          expect(actions.fetchItems).not.toHaveBeenCalled();
        });
      });

      it('calls getDrawerBodyHeight and setDrawerBodyHeight when resize directive is triggered', () => {
        const { value } = getBinding(getDrawer().element, 'gl-resize-observer');

        value();

        expect(getDrawerBodyHeight).toHaveBeenCalledWith(wrapper.findComponent(GlDrawer).element);

        expect(actions.setDrawerBodyHeight).toHaveBeenCalledWith(
          expect.any(Object),
          MOCK_DRAWER_BODY_HEIGHT,
        );
      });
    });

    describe('without features', () => {
      it('renders skeleton loader when fetching', async () => {
        setup([], true);

        await nextTick();

        const scroll = findInfiniteScroll();
        const skeletonLoader = findSkeletonLoader();

        expect(scroll.exists()).toBe(false);
        expect(skeletonLoader.exists()).toBe(true);
      });

      it('renders infinite scroll loader when NOT fetching', async () => {
        setup([], false);

        await nextTick();

        const scroll = findInfiniteScroll();
        const skeletonLoader = findSkeletonLoader();

        expect(scroll.exists()).toBe(true);
        expect(skeletonLoader.exists()).toBe(false);
      });
    });

    describe('focus', () => {
      it('takes focus after being opened', () => {
        setup([], false);
        expect(document.activeElement).not.toBe(getDrawer().element);
        getDrawer().vm.$emit('opened');
        expect(document.activeElement).toBe(getDrawer().element);
      });
    });
  });
});
