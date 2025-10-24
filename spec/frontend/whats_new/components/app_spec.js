import { GlDrawer } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import App from '~/whats_new/components/app.vue';
import FeaturedCarousel from '~/whats_new/components/featured_carousel.vue';
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
  let trackingSpy;

  const withClose = jest.fn();
  const updateHelpMenuUnreadBadge = jest.fn();

  const createWrapper = (options = {}) => {
    const {
      glFeatures = {},
      shallow = false,
      includeWithClose = false,
      stateOverrides = {},
    } = options;

    actions = {
      openDrawer: jest.fn(),
      closeDrawer: jest.fn(),
      fetchItems: jest.fn(),
      setDrawerBodyHeight: jest.fn(),
      setReadArticles: jest.fn(),
    };

    store = new Vuex.Store({
      actions,
      state: {
        open: false,
        features: [],
        drawerBodyHeight: MOCK_DRAWER_BODY_HEIGHT,
        fetching: false,
        pageInfo: {},
        readArticles: [],
        ...stateOverrides,
      },
    });

    const mountOptions = {
      store,
      propsData: {
        versionDigest: 'version-digest',
        initialReadArticles: [1, 2],
        mostRecentReleaseItemsCount: 3,
        updateHelpMenuUnreadBadge,
        ...(includeWithClose && { withClose }),
      },
      ...(Object.keys(glFeatures).length > 0 && { provide: { glFeatures } }),
      ...(!shallow && {
        directives: {
          GlResizeObserver: createMockDirective('gl-resize-observer'),
        },
        attachTo: document.body,
      }),
    };

    wrapper = shallow ? shallowMount(App, mountOptions) : mount(App, mountOptions);
  };

  const setup = async (features, fetching) => {
    document.body.dataset.page = 'test-page';
    document.body.dataset.namespaceId = 'namespace-840';

    trackingSpy = mockTracking('_category_', null, jest.spyOn);

    createWrapper({
      includeWithClose: true,
      stateOverrides: {
        open: true,
        features,
        fetching,
      },
    });

    await nextTick();
  };

  const getDrawer = () => wrapper.findComponent(GlDrawer);
  const findFeaturedCarousel = () => wrapper.findComponent(FeaturedCarousel);

  afterEach(() => {
    if (trackingSpy) {
      unmockTracking();
      trackingSpy = null;
    }
  });

  describe("the what's new feature carousel", () => {
    it('renders properly', () => {
      createWrapper({
        shallow: true,
      });

      expect(findFeaturedCarousel().exists()).toBe(true);
    });
  });

  describe('drawer behavior', () => {
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

      it('sets readArticles from initialReadArticles', () => {
        expect(actions.setReadArticles).toHaveBeenCalledWith(expect.any(Object), [1, 2]);
      });

      it('calls updateHelpMenuUnreadBadge when readArticles is updated', async () => {
        store.state.readArticles = [1, 2, 3];

        await nextTick();

        expect(updateHelpMenuUnreadBadge).toHaveBeenCalledWith(0);
      });

      it('dispatches closeDrawer when clicking close', () => {
        getDrawer().vm.$emit('close');
        expect(actions.closeDrawer).toHaveBeenCalled();
        expect(withClose).toHaveBeenCalled();
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
        expect(wrapper.find('[data-testid="toggle-feature-name"]').text()).toBe('Whats New Drawer');
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
