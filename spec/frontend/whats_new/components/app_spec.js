import { GlDrawer, GlInfiniteScroll } from '@gitlab/ui';
import { createLocalVue, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import { mockTracking, unmockTracking, triggerEvent } from 'helpers/tracking_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import App from '~/whats_new/components/app.vue';
import { getDrawerBodyHeight } from '~/whats_new/utils/get_drawer_body_height';

const MOCK_DRAWER_BODY_HEIGHT = 42;

jest.mock('~/whats_new/utils/get_drawer_body_height', () => ({
  getDrawerBodyHeight: jest.fn().mockImplementation(() => MOCK_DRAWER_BODY_HEIGHT),
}));

const localVue = createLocalVue();
localVue.use(Vuex);

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
    };

    store = new Vuex.Store({
      actions,
      state,
    });

    wrapper = mount(App, {
      localVue,
      store,
      propsData: buildProps(),
      directives: {
        GlResizeObserver: createMockDirective(),
      },
    });
  };

  const findInfiniteScroll = () => wrapper.find(GlInfiniteScroll);

  const setup = async () => {
    document.body.dataset.page = 'test-page';
    document.body.dataset.namespaceId = 'namespace-840';

    trackingSpy = mockTracking('_category_', null, jest.spyOn);
    buildWrapper();

    wrapper.vm.$store.state.features = [
      { title: 'Whats New Drawer', url: 'www.url.com', release: 3.11 },
    ];
    wrapper.vm.$store.state.drawerBodyHeight = MOCK_DRAWER_BODY_HEIGHT;
    await wrapper.vm.$nextTick();
  };

  afterEach(() => {
    wrapper.destroy();
    unmockTracking();
  });

  describe('gitlab.com', () => {
    beforeEach(() => {
      setup();
    });

    const getDrawer = () => wrapper.find(GlDrawer);
    const getBackdrop = () => wrapper.find('.whats-new-modal-backdrop');

    it('contains a drawer', () => {
      expect(getDrawer().exists()).toBe(true);
    });

    it('dispatches openDrawer and tracking calls when mounted', () => {
      expect(actions.openDrawer).toHaveBeenCalledWith(expect.any(Object), 'version-digest');
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_whats_new_drawer', {
        label: 'namespace_id',
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
      wrapper.vm.$store.state.open = openState;

      await wrapper.vm.$nextTick();

      expect(getDrawer().props('open')).toBe(openState);
    });

    it('renders features when provided via ajax', () => {
      expect(actions.fetchItems).toHaveBeenCalled();
      expect(wrapper.find('[data-test-id="feature-title"]').text()).toBe('Whats New Drawer');
    });

    it('send an event when feature item is clicked', () => {
      trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);

      const link = wrapper.find('.whats-new-item-title-link');
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

      expect(scroll.props()).toMatchObject({
        fetchedItems: wrapper.vm.$store.state.features.length,
        maxListHeight: MOCK_DRAWER_BODY_HEIGHT,
      });
    });

    describe('bottomReached', () => {
      const emitBottomReached = () => findInfiniteScroll().vm.$emit('bottomReached');

      beforeEach(() => {
        actions.fetchItems.mockClear();
      });

      it('when nextPage exists it calls fetchItems', () => {
        wrapper.vm.$store.state.pageInfo = { nextPage: 840 };
        emitBottomReached();

        expect(actions.fetchItems).toHaveBeenCalledWith(expect.anything(), {
          page: 840,
          versionDigest: 'version-digest',
        });
      });

      it('when nextPage does not exist it does not call fetchItems', () => {
        wrapper.vm.$store.state.pageInfo = { nextPage: null };
        emitBottomReached();

        expect(actions.fetchItems).not.toHaveBeenCalled();
      });
    });

    it('calls getDrawerBodyHeight and setDrawerBodyHeight when resize directive is triggered', () => {
      const { value } = getBinding(getDrawer().element, 'gl-resize-observer');

      value();

      expect(getDrawerBodyHeight).toHaveBeenCalledWith(wrapper.find(GlDrawer).element);

      expect(actions.setDrawerBodyHeight).toHaveBeenCalledWith(
        expect.any(Object),
        MOCK_DRAWER_BODY_HEIGHT,
      );
    });
  });
});
