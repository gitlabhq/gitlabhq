import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GlobalSearchHeaderApp from '~/super_sidebar/components/global_search/components/global_search_header_app.vue';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SearchModal from '~/super_sidebar/components/global_search/components/global_search.vue';

jest.mock('~/lib/utils/css_utils', () => ({
  isNarrowScreen: jest.fn(),
  isNarrowScreenAddListener: jest.fn(),
  isNarrowScreenRemoveListener: jest.fn(),
}));

describe('GlobalSearchHeaderApp', () => {
  let wrapper;

  const createComponent = ({ features = { searchButtonTopRight: true } } = {}) => {
    wrapper = shallowMountExtended(GlobalSearchHeaderApp, {
      provide: {
        glFeatures: {
          ...features,
        },
      },
    });
  };

  const findSearchButton = () => wrapper.findByTestId('super-sidebar-search-button');
  const findSearchModal = () => wrapper.findComponent(SearchModal);

  describe('Render', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(async () => {
      createComponent();
      await waitForPromises();
    });

    it('should render search button', () => {
      expect(findSearchButton().exists()).toBe(true);
    });

    it('search button should have tracking', async () => {
      const { trackEventSpy } = bindInternalEventDocument(findSearchButton().element);
      await findSearchButton().vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        'click_search_button_to_activate_command_palette',
        { label: 'top_right' },
        undefined,
      );
    });

    it('should render search modal', () => {
      expect(findSearchModal().exists()).toBe(true);
    });

    describe('when feature flag is off', () => {
      beforeEach(() => {
        createComponent({ features: { searchButtonTopRight: false } });
      });

      it('should not render search button', () => {
        expect(findSearchButton().exists()).toBe(false);
      });

      it('should not render search modal', () => {
        expect(findSearchModal().exists()).toBe(false);
      });
    });
  });
});
