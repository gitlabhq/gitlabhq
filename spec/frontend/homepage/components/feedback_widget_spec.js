import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FeedbackWidget from '~/homepage/components/feedback_widget.vue';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import {
  EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
  TRACKING_LABEL_FEEDBACK,
} from '~/homepage/tracking_constants';

describe('FeedbackWidget', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(FeedbackWidget, {
      propsData: props,
    });
  };

  const findExternalFeedbackLink = () => wrapper.findByTestId('external-feedback-link');

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the widget title', () => {
      const title = wrapper.find('h2');
      expect(title.text()).toBe('Share your feedback');
    });

    it('renders the description text', () => {
      const description = wrapper.find('p');
      expect(description.text()).toBe(
        'Help us improve the new homepage by sharing your thoughts and suggestions.',
      );
    });

    it('renders external feedback link', () => {
      const externalLink = findExternalFeedbackLink();

      expect(externalLink.exists()).toBe(true);
      expect(externalLink.attributes('href')).toBe(
        'https://gitlab.com/gitlab-org/gitlab/-/issues/553938',
      );
      expect(externalLink.attributes('target')).toBe('_blank');
      expect(externalLink.text()).toBe('Leave feedback');
    });
  });

  describe('tracking', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(() => {
      createComponent();
    });

    it('tracks clicks on external feedback link', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      const externalLink = findExternalFeedbackLink();

      externalLink.vm.$emit('click');

      expect(trackEventSpy).toHaveBeenCalledWith(
        EVENT_USER_FOLLOWS_LINK_ON_HOMEPAGE,
        {
          label: TRACKING_LABEL_FEEDBACK,
          property: 'external_feedback_link',
        },
        undefined,
      );
    });
  });
});
