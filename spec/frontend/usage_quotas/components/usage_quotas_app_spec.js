import { GlAlert, GlTab } from '@gitlab/ui';
import { FEATURE_CATEGORY_HEADER } from '~/lib/apollo/instrumentation_link';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import getNamespaceStorageQuery from '~/usage_quotas/storage/namespace/queries/namespace_storage.query.graphql';
import { getStorageTabMetadata } from '~/usage_quotas/storage/utils';
import UsageQuotasApp from '~/usage_quotas/components/usage_quotas_app.vue';
import Tracking from '~/tracking';
import { defaultProvide, provideWithTabs } from '../mock_data';

describe('UsageQuotasApp', () => {
  let wrapper;

  const createComponent = ({ provide = {} } = {}) => {
    wrapper = shallowMountExtended(UsageQuotasApp, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findTabs = () => wrapper.findAllComponents(GlTab);

  describe('when tabs array is empty', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows error alert', () => {
      expect(findGlAlert().text()).toContain(
        'Something went wrong while loading Usage quotas Tabs',
      );
    });
  });

  describe('when there are tabs', () => {
    beforeEach(() => {
      jest.spyOn(Tracking, 'event');
      createComponent({
        provide: provideWithTabs,
      });
    });

    it('does not show error alert', () => {
      expect(findGlAlert().exists()).toBe(false);
    });

    it('tracks internal events when user clicks on a tab that has tracking data', () => {
      findTabs().at(0).vm.$emit('click');

      expect(Tracking.event).toHaveBeenCalledWith(
        undefined,
        provideWithTabs.tabs[0].tracking.action,
        expect.any(Object),
      );
    });

    it('does not track any event when user clicks on a tab that does not have tracking data', () => {
      findTabs().at(1).vm.$emit('click');

      expect(Tracking.event).not.toHaveBeenCalledWith();
    });

    it('sets initial tab hash to window.location.href', () => {
      expect(window.location.href).toContain(provideWithTabs.tabs[0].hash);
    });

    it('updates window.location.href on tab change', () => {
      findTabs().at(1).vm.$emit('click');
      expect(window.location.href).toContain(provideWithTabs.tabs[1].hash);
    });

    it('updates gon.feature_category according to initial tab metadata', () => {
      expect(gon.feature_category).toContain(provideWithTabs.tabs[0].featureCategory);
    });

    describe('apollo instrumentationLink', () => {
      let tabs;
      const originalFetch = global.fetch;

      beforeEach(() => {
        global.fetch = jest.fn().mockResolvedValue({
          ok: true,
          text: () => Promise.resolve('{"data":{"namespace": null}}'),
        });
        // This is just so we can create the object properly in getStorageTabMetadata()
        setHTMLFixture('<div id="js-storage-usage-app"></div>');
        tabs = [...provideWithTabs.tabs, getStorageTabMetadata({ parseProvideData: () => {} })];

        createComponent({ provide: { tabs } });
      });

      afterEach(() => {
        global.fetch = originalFetch;
        resetHTMLFixture();
      });

      it('sets initial tab feature category on apollo call', async () => {
        const apolloClient = tabs[2].component.apolloProvider.defaultClient;

        await apolloClient.query({
          query: getNamespaceStorageQuery,
        });

        expect(fetch).toHaveBeenCalledWith(
          '/api/graphql',
          expect.objectContaining({
            headers: expect.objectContaining({
              [FEATURE_CATEGORY_HEADER]: tabs[0].featureCategory,
            }),
          }),
        );
      });

      it('updates apollo feature category header on tab change', async () => {
        findTabs().at(2).vm.$emit('click');

        const apolloClient = tabs[2].component.apolloProvider.defaultClient;

        await apolloClient.query({
          query: getNamespaceStorageQuery,
        });

        expect(fetch).toHaveBeenCalledWith(
          '/api/graphql',
          expect.objectContaining({
            headers: expect.objectContaining({
              [FEATURE_CATEGORY_HEADER]: tabs[2].featureCategory,
            }),
          }),
        );
      });
    });
  });
});
