import { mountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import TranscendPromoCard from '~/whats_new/components/transcend_promo_card.vue';

describe('TranscendPromoCard', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(TranscendPromoCard);
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the heading', () => {
    expect(wrapper.find('h3').text()).toContain('GitLab Transcend');
  });

  it('renders the body text', () => {
    expect(wrapper.find('p').text()).toContain('join us online');
  });

  it('renders the register link with correct URL', () => {
    const link = wrapper.findByTestId('transcend-register-link');

    expect(link.attributes('target')).toBe('_blank');

    expect(link.attributes('href')).toBe(
      'https://about.gitlab.com/events/transcend/virtual/?utm_medium=product&utm_campaign=eg_global_cmp_webcast_x_en_20260610_gitlabtranscend_virtual&utm_content=in-product-placement_x_x',
    );
  });

  describe('tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    it('fires tracking event on CTA click', () => {
      const { triggerEvent, trackEventSpy } = bindInternalEventDocument(wrapper.element);
      triggerEvent('[data-testid="transcend-register-link"]');

      expect(trackEventSpy).toHaveBeenCalledWith('click_whats_new_transcend_register', {});
    });
  });
});
