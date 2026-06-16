import { GlDrawer } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import { createTestingPinia } from '@pinia/testing';
import { PiniaVuePlugin } from 'pinia';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import App from '~/whats_new/components/app.vue';
import TranscendPromoCard from '~/whats_new/components/transcend_promo_card.vue';
import { useWhatsNew } from '~/whats_new/store';

Vue.use(PiniaVuePlugin);

describe('App', () => {
  let wrapper;
  let pinia;
  let store;
  let trackingSpy;

  const updateHelpMenuUnreadBadge = jest.fn();

  const createWrapper = (options = {}) => {
    const { glFeatures = {}, shallow = false, stateOverrides = {}, props = {} } = options;

    Object.assign(store, stateOverrides);

    const mountOptions = {
      pinia,
      propsData: {
        versionDigest: 'version-digest',
        initialReadArticles: [1, 2],
        mostRecentReleaseItemsCount: 3,
        updateHelpMenuUnreadBadge,
        placement: 'help_menu',
        ...props,
      },
      ...(Object.keys(glFeatures).length > 0 && { provide: { glFeatures } }),
      ...(!shallow && {
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
      stateOverrides: {
        open: true,
        features,
        fetching,
      },
    });

    await nextTick();
  };

  const getDrawer = () => wrapper.findComponent(GlDrawer);
  const findTranscendPromoCard = () => wrapper.findComponent(TranscendPromoCard);

  beforeEach(() => {
    pinia = createTestingPinia();
    store = useWhatsNew();
  });

  afterEach(() => {
    if (trackingSpy) {
      unmockTracking();
      trackingSpy = null;
    }
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

      it('dispatches openDrawer and fires view_whats_new_drawer with the placement', () => {
        expect(store.openDrawer).toHaveBeenCalledWith('version-digest');
        expect(trackingSpy).toHaveBeenCalledWith(
          undefined,
          'view_whats_new_drawer',
          expect.objectContaining({
            label: 'namespace_id',
            value: 'namespace-840',
            property: 'help_menu',
          }),
        );
      });

      it('tracks the candidate placement when mounted with placement=profile_menu', () => {
        createWrapper({
          props: { placement: 'profile_menu' },
          stateOverrides: { open: true, features: [], fetching: false },
        });
        expect(trackingSpy).toHaveBeenCalledWith(
          undefined,
          'view_whats_new_drawer',
          expect.objectContaining({
            label: 'namespace_id',
            value: 'namespace-840',
            property: 'profile_menu',
          }),
        );
      });

      it('sets readArticles from initialReadArticles', () => {
        expect(store.setReadArticles).toHaveBeenCalledWith([1, 2]);
      });

      it('calls updateHelpMenuUnreadBadge when readArticles is updated', async () => {
        store.readArticles = [1, 2, 3];

        await nextTick();

        expect(updateHelpMenuUnreadBadge).toHaveBeenCalledWith(0);
      });

      it.each([
        ['drawer close event', () => getDrawer().vm.$emit('close')],
        ['backdrop click', () => getBackdrop().trigger('click')],
      ])('calls closeDrawer on %s', (_, trigger) => {
        trigger();
        expect(store.closeDrawer).toHaveBeenCalled();
      });

      it.each([true, false])('passes open property', async (openState) => {
        store.open = openState;

        await nextTick();

        expect(getDrawer().props('open')).toBe(openState);
      });

      it('renders features when provided via ajax', () => {
        expect(store.fetchItems).toHaveBeenCalled();
        expect(wrapper.find('[data-testid="toggle-feature-name"]').text()).toBe('Whats New Drawer');
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

    describe('fetchInitialItems', () => {
      it('fetches up to 3 pages sequentially', async () => {
        document.body.dataset.page = 'test-page';
        document.body.dataset.namespaceId = 'namespace-840';

        let fetchCount = 0;
        store.fetchItems.mockImplementation(() => {
          fetchCount += 1;
          if (fetchCount < 3) {
            store.pageInfo = { nextPage: fetchCount + 1 };
          } else {
            store.pageInfo = { nextPage: null };
          }
          return Promise.resolve();
        });

        createWrapper({
          stateOverrides: {
            open: true,
            features: [],
            pageInfo: { nextPage: null },
          },
        });

        await nextTick();
        await nextTick();
        await nextTick();
        await nextTick();

        expect(store.fetchItems).toHaveBeenCalledTimes(3);
        expect(store.fetchItems).toHaveBeenNthCalledWith(1, {
          page: undefined,
          versionDigest: 'version-digest',
        });
        expect(store.fetchItems).toHaveBeenNthCalledWith(2, {
          page: 2,
          versionDigest: 'version-digest',
        });
        expect(store.fetchItems).toHaveBeenNthCalledWith(3, {
          page: 3,
          versionDigest: 'version-digest',
        });
      });

      it('stops fetching when there is no next page', async () => {
        document.body.dataset.page = 'test-page';
        document.body.dataset.namespaceId = 'namespace-840';

        store.fetchItems.mockImplementation(() => {
          store.pageInfo = { nextPage: null };
          return Promise.resolve();
        });

        createWrapper({
          stateOverrides: {
            open: true,
            features: [],
            pageInfo: { nextPage: null },
          },
        });

        await nextTick();
        await nextTick();

        expect(store.fetchItems).toHaveBeenCalledTimes(1);
      });
    });

    describe('transcend promo card', () => {
      it('does not render by default', () => {
        createWrapper({
          stateOverrides: { open: true, features: [], fetching: false },
        });

        expect(findTranscendPromoCard().exists()).toBe(false);
      });

      it('renders when showTranscendPromo is true', () => {
        createWrapper({
          stateOverrides: { open: true, features: [], fetching: false },
          props: { showTranscendPromo: true },
        });

        expect(findTranscendPromoCard().exists()).toBe(true);
      });
    });

    describe('handleLoadMore', () => {
      it('fetches next page when nextPage exists', async () => {
        document.body.dataset.page = 'test-page';
        document.body.dataset.namespaceId = 'namespace-840';

        createWrapper({
          stateOverrides: {
            open: true,
            features: [{ name: 'Feature', documentation_link: 'www.url.com', release: 3.11 }],
            pageInfo: { nextPage: 2 },
          },
        });

        await nextTick();

        store.fetchItems.mockClear();

        wrapper.findComponent({ name: 'OtherUpdates' }).vm.$emit('load-more');

        expect(store.fetchItems).toHaveBeenCalledWith({
          page: 2,
          versionDigest: 'version-digest',
        });
      });

      it('does not fetch when nextPage is null', async () => {
        document.body.dataset.page = 'test-page';
        document.body.dataset.namespaceId = 'namespace-840';

        createWrapper({
          stateOverrides: {
            open: true,
            features: [{ name: 'Feature', documentation_link: 'www.url.com', release: 3.11 }],
            pageInfo: { nextPage: null },
          },
        });

        await nextTick();

        store.fetchItems.mockClear();

        wrapper.findComponent({ name: 'OtherUpdates' }).vm.$emit('load-more');

        expect(store.fetchItems).not.toHaveBeenCalled();
      });
    });
  });
});
