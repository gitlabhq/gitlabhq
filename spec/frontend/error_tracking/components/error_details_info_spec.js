import { GlLink, GlCard } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import ErrorDetailsInfo from '~/error_tracking/components/error_details_info.vue';
import { trackClickErrorLinkToSentryOptions } from '~/error_tracking/events_tracking';
import Tracking from '~/tracking';

jest.mock('~/tracking');

describe('ErrorDetails', () => {
  let wrapper;

  const MOCK_DEFAULT_ERROR = {
    id: 'gid://gitlab/Gitlab::ErrorTracking::DetailedError/129381',
    sentryId: 129381,
    title: 'Issue title',
    externalUrl: 'http://sentry.gitlab.net/gitlab',
    firstSeen: '2017-05-26T13:32:48Z',
    lastSeen: '2018-05-26T13:32:48Z',
    count: 12,
    userCount: 2,
    integrated: false,
  };

  function mountComponent(error = {}) {
    wrapper = shallowMountExtended(ErrorDetailsInfo, {
      stubs: { GlCard },
      propsData: {
        error: {
          ...MOCK_DEFAULT_ERROR,
          ...error,
        },
      },
    });
  }

  beforeEach(() => {
    mountComponent();
  });

  it('should render a card with error counts', () => {
    expect(wrapper.findByTestId('error-count-card').text()).toMatchInterpolatedText('Events 12');
  });

  it('should render a card with user counts', () => {
    expect(wrapper.findByTestId('user-count-card').text()).toMatchInterpolatedText('Users 2');
  });

  describe('first seen card', () => {
    it('if firstSeen is missing, does not render a card', () => {
      mountComponent({
        firstSeen: undefined,
      });
      expect(wrapper.findByTestId('first-release-card').exists()).toBe(false);
    });

    it('if firstSeen exists renders a card', () => {
      mountComponent({
        firstSeen: '2017-05-26T13:32:48Z',
      });
      const card = wrapper.findByTestId('first-release-card');
      expect(card.exists()).toBe(true);
      expect(card.text()).toContain('First seen');
      expect(card.findComponent(TimeAgoTooltip).exists()).toBe(true);
      expect(card.findComponent(TimeAgoTooltip).props('time')).toBe('2017-05-26T13:32:48Z');
    });

    describe('if firstReleaseVersion link exists', () => {
      it('shows the shortened release tag as text, if error is integrated', () => {
        mountComponent({
          firstReleaseVersion: 'first-release-version',
          firstSeen: '2023-04-20T17:02:06+00:00',
          integrated: true,
        });
        const card = wrapper.findByTestId('first-release-card');
        expect(card.text()).toMatchInterpolatedText('First seen first-rele');
        expect(card.findComponent(GlLink).exists()).toBe(false);
      });

      it('renders a link to the release, if error is not integrated', () => {
        mountComponent({
          externalBaseUrl: 'external-base-url',
          firstReleaseVersion: 'first-release-version',
          firstSeen: '2023-04-20T17:02:06+00:00',
          integrated: false,
        });
        expect(
          wrapper.findByTestId('first-release-card').findComponent(GlLink).attributes('href'),
        ).toBe('external-base-url/releases/first-release-version');
      });
    });
  });

  describe('last seen card', () => {
    it('if lastSeen is missing, does not render a card', () => {
      mountComponent({
        lastSeen: undefined,
      });
      expect(wrapper.findByTestId('last-release-card').exists()).toBe(false);
    });

    it('if lastSeen exists renders a card', () => {
      mountComponent({
        lastSeen: '2017-05-26T13:32:48Z',
      });
      const card = wrapper.findByTestId('last-release-card');
      expect(card.exists()).toBe(true);
      expect(card.text()).toContain('Last seen');
      expect(card.findComponent(TimeAgoTooltip).exists()).toBe(true);
      expect(card.findComponent(TimeAgoTooltip).props('time')).toBe('2017-05-26T13:32:48Z');
    });

    describe('if lastReleaseVersion link exists', () => {
      it('shows the shortened release tag as text, if error is integrated', () => {
        mountComponent({
          lastReleaseVersion: 'last-release-version',
          lastSeen: '2023-04-20T17:02:06+00:00',
          integrated: true,
        });
        const card = wrapper.findByTestId('last-release-card');
        expect(card.text()).toMatchInterpolatedText('Last seen last-relea');
        expect(card.findComponent(GlLink).exists()).toBe(false);
      });

      it('renders a link to the release, if error is not integrated', () => {
        mountComponent({
          externalBaseUrl: 'external-base-url',
          lastReleaseVersion: 'last-release-version',
          lastSeen: '2023-04-20T17:02:06+00:00',
          integrated: false,
        });
        expect(
          wrapper.findByTestId('last-release-card').findComponent(GlLink).attributes('href'),
        ).toBe('external-base-url/releases/last-release-version');
      });
    });
  });

  describe('gitlab commit link', () => {
    it('does not render a card with gitlab commit link, if gitlabCommitPath does not exist', () => {
      expect(wrapper.findByTestId('gitlab-commit-card').exists()).toBe(false);
    });

    it('should render a card with gitlab commit link, if gitlabCommitPath exists', () => {
      mountComponent({
        gitlabCommit: 'gitlab-long-commit',
        gitlabCommitPath: 'commit-path',
      });
      const card = wrapper.findByTestId('gitlab-commit-card');
      expect(card.exists()).toBe(true);
      expect(card.text()).toContain('GitLab commit');
      const link = card.findComponent(GlLink);
      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe('commit-path');
      expect(link.text()).toBe('gitlab-lon');
    });
  });

  describe('external url link', () => {
    const findExternalUrlLink = () => wrapper.findByTestId('external-url-link');

    it('should not render an external link if integrated', () => {
      mountComponent({
        integrated: true,
        externalUrl: 'external-url',
      });
      expect(findExternalUrlLink().exists()).toBe(false);
    });

    it('should render an external link if not integrated', () => {
      mountComponent({
        integrated: false,
        externalUrl: 'external-url',
      });
      const link = findExternalUrlLink();
      expect(link.exists()).toBe(true);
      expect(link.text()).toContain('external-url');
    });

    it('should track external Sentry link views', async () => {
      Tracking.event.mockClear();

      mountComponent({
        integrated: false,
        externalUrl: 'external-url',
      });
      await findExternalUrlLink().trigger('click');

      const { category, action, label, property } =
        trackClickErrorLinkToSentryOptions('external-url');
      expect(Tracking.event).toHaveBeenCalledWith(category, action, { label, property });
    });
  });
});
