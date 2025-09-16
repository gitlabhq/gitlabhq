import { GlCard, GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import FeaturedCard from '~/whats_new/components/featured_card.vue';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';

describe('FeaturedCard', () => {
  let wrapper;

  const defaultProps = {
    title: 'Test Feature Title',
    description: 'This is a test description for the featured card component.',
    buttonLink: 'https://example.com/learn-more',
    trackingEvent: 'click_learn_more_in_duo_core_featured_update_card',
  };

  const buildWrapper = (props = {}) => {
    wrapper = mount(FeaturedCard, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findCard = () => wrapper.findComponent(GlCard);
  const findButton = () => wrapper.findComponent(GlButton);
  const findTitle = () => wrapper.find('h3');
  const findDescription = () => wrapper.find('div').text();

  describe('rendering', () => {
    beforeEach(() => {
      buildWrapper();
    });

    it('renders the card component', () => {
      expect(findCard().exists()).toBe(true);
    });

    it('renders the title correctly', () => {
      expect(findTitle().text().trim()).toBe(defaultProps.title);
    });

    it('renders the description correctly', () => {
      expect(findDescription()).toContain(defaultProps.description);
    });

    it('renders the button with correct properties', () => {
      const button = findButton();

      expect(button.attributes('href')).toBe(defaultProps.buttonLink);
    });
  });

  describe('tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(() => {
      buildWrapper();
    });

    it('tracks when the learn more button is clicked', async () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      trackEventSpy.mockClear();

      findButton().vm.$emit('click');
      await Vue.nextTick();

      expect(trackEventSpy).toHaveBeenCalledWith(
        'click_learn_more_in_duo_core_featured_update_card',
        {},
        undefined,
      );
    });
  });
});
