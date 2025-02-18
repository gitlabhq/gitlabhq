import { GlBadge, GlPopover } from '@gitlab/ui';
import uniqueId from 'lodash/uniqueId';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import TopicBadges from '~/vue_shared/components/topic_badges.vue';

jest.mock('lodash/uniqueId');

describe('Topic Badges', () => {
  let wrapper;

  const defaultProps = {
    showLabel: true,
    topics: ['Vue.js', 'Ruby', 'JavaScript', 'docker'],
  };

  const findBadges = () => wrapper.findAllComponents(GlBadge);
  const findFirstBadge = () => wrapper.findComponent(GlBadge);
  const findMoreTopicsLabel = () => wrapper.findByTestId('more-topics-label');
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findTopicsLabel = () => wrapper.findByText('Topics:');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(TopicBadges, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  describe('with more than 3 topics', () => {
    beforeEach(() => {
      uniqueId.mockImplementation((prefix) => `${prefix}1`);
      createComponent();
    });

    it('renders first three topics', () => {
      const firstThreeTopics = defaultProps.topics.slice(0, 3);
      const firstThreeBadges = findBadges().wrappers.slice(0, 3);
      const firstThreeBadgesText = firstThreeBadges.map((badge) => badge.text());
      const firstThreeBadgesHref = firstThreeBadges.map((badge) => badge.attributes('href'));

      expect(firstThreeBadgesText).toEqual(firstThreeTopics);
      expect(firstThreeBadgesHref).toEqual(
        firstThreeTopics.map((topic) => `/explore/projects/topics/${encodeURIComponent(topic)}`),
      );
    });

    it('renders label to open popover', () => {
      const expectedButtonId = 'project-topics-popover-1';

      expect(findMoreTopicsLabel().attributes('id')).toBe(expectedButtonId);
      expect(findPopover().props('target')).toBe(expectedButtonId);
    });

    it('renders the rest of the topics in a popover', () => {
      const topics = defaultProps.topics.slice(3);
      const badges = findPopover().findAllComponents(GlBadge).wrappers;
      const badgesText = badges.map((badge) => badge.text());
      const badgesHref = badges.map((badge) => badge.attributes('href'));

      expect(topics).toEqual(badgesText);
      expect(badgesHref).toEqual(
        topics.map((topic) => `/explore/projects/topics/${encodeURIComponent(topic)}`),
      );
    });
  });

  describe.each`
    topics
    ${defaultProps.topics.slice(0, 2)}
    ${defaultProps.topics.slice(0, 3)}
  `('with $topics.length topics', ({ topics }) => {
    beforeEach(() => {
      createComponent({
        props: {
          topics,
        },
      });
    });

    it('does not render label to open popover', () => {
      expect(findMoreTopicsLabel().exists()).toBe(false);
    });

    it('does not render popover', () => {
      expect(findPopover().exists()).toBe(false);
    });
  });

  describe('truncation', () => {
    it('truncates long name and shows tooltip with full name', () => {
      const topicWithLongName = 'topic with very very very long name';

      createComponent({
        props: {
          topics: [topicWithLongName, ...defaultProps.topics],
        },
      });

      const tooltip = getBinding(findFirstBadge().element, 'gl-tooltip');

      expect(findFirstBadge().text()).toBe('topic with ver…');
      expect(tooltip.value).toBe(topicWithLongName);
    });

    it('does not show tooltip if topic is not truncated', () => {
      createComponent();

      const tooltip = getBinding(findFirstBadge().element, 'gl-tooltip');

      expect(findFirstBadge().text()).toBe('Vue.js');
      expect(tooltip.value).toBe(null);
    });
  });

  describe('`showLabel` prop', () => {
    describe('when `showLabel` is true', () => {
      it('renders the topics label', () => {
        createComponent();

        expect(findTopicsLabel().exists()).toBe(true);
      });
    });

    describe('when `showLabel` is false', () => {
      it('does not render the topics label', () => {
        createComponent({
          props: {
            showLabel: false,
          },
        });

        expect(findTopicsLabel().exists()).toBe(false);
      });
    });
  });

  describe('with relative url', () => {
    beforeEach(() => {
      gon.relative_url_root = '/gitlab/something//';
      createComponent();
    });

    it('passes correct url prop to badge', () => {
      expect(findFirstBadge().props('href')).toBe(
        `/gitlab/something/explore/projects/topics/${defaultProps.topics[0]}`,
      );
    });
  });
});
