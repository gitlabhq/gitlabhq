import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import CodeQualityPage from '~/merge_requests/reports/code_quality/code_quality_page.vue';
import CodeQualityProvider from '~/merge_requests/reports/code_quality/code_quality_provider.vue';
import CodeQualityContent from '~/merge_requests/reports/code_quality/code_quality_content.vue';

describe('CodeQualityPage', () => {
  let wrapper;

  const DEFAULT_MR_PROP = { id: 1 };

  const findProvider = () => wrapper.findComponent(CodeQualityProvider);
  const findContent = () => wrapper.findComponent(CodeQualityContent);

  const createComponent = () => {
    wrapper = shallowMountExtended(CodeQualityPage, {
      propsData: {
        mr: DEFAULT_MR_PROP,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders CodeQualityProvider with mr prop', () => {
    expect(findProvider().props('mr')).toBe(DEFAULT_MR_PROP);
  });

  it('renders CodeQualityContent inside provider', () => {
    expect(findContent().exists()).toBe(true);
  });

  describe('tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    it('tracks view_merge_request_report on mount', () => {
      createComponent();
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      expect(trackEventSpy).toHaveBeenCalledWith(
        'view_merge_request_report',
        { label: 'code_quality' },
        undefined,
      );
    });
  });
});
