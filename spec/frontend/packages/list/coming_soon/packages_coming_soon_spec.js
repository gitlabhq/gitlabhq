import { GlEmptyState, GlSkeletonLoader, GlLabel } from '@gitlab/ui';
import { mount, createLocalVue } from '@vue/test-utils';
import ComingSoon from '~/packages/list/coming_soon/packages_coming_soon.vue';
import { TrackingActions } from '~/packages/shared/constants';
import { asViewModel } from './mock_data';
import Tracking from '~/tracking';
import VueApollo, { ApolloQuery } from 'vue-apollo';

jest.mock('~/packages/list/coming_soon/helpers.js');

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('packages_coming_soon', () => {
  let wrapper;

  const findSkeletonLoader = () => wrapper.find(GlSkeletonLoader);
  const findAllIssues = () => wrapper.findAll('[data-testid="issue-row"]');
  const findIssuesData = () =>
    findAllIssues().wrappers.map(x => {
      const titleLink = x.find('[data-testid="issue-title-link"]');
      const milestone = x.find('[data-testid="milestone"]');
      const issueIdLink = x.find('[data-testid="issue-id-link"]');
      const labels = x.findAll(GlLabel);

      const issueId = Number(issueIdLink.text().substr(1));

      return {
        id: issueId,
        iid: issueId,
        title: titleLink.text(),
        webUrl: titleLink.attributes('href'),
        labels: labels.wrappers.map(label => ({
          color: label.props('backgroundColor'),
          title: label.props('title'),
          scoped: label.props('scoped'),
        })),
        ...(milestone.exists() ? { milestone: { title: milestone.text() } } : {}),
      };
    });
  const findIssueTitleLink = () => wrapper.find('[data-testid="issue-title-link"]');
  const findIssueIdLink = () => wrapper.find('[data-testid="issue-id-link"]');
  const findEmptyState = () => wrapper.find(GlEmptyState);

  const mountComponent = (testParams = {}) => {
    const $apolloData = {
      loading: testParams.isLoading || false,
    };

    wrapper = mount(ComingSoon, {
      localVue,
      propsData: {
        illustration: 'foo',
        projectPath: 'foo',
        suggestedContributionsPath: 'foo',
      },
      stubs: {
        ApolloQuery,
        GlLink: true,
      },
      mocks: {
        $apolloData,
      },
    });

    // Mock the GraphQL query result
    wrapper.find(ApolloQuery).setData({
      result: {
        data: testParams.issues || asViewModel,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when loading', () => {
    beforeEach(() => mountComponent({ isLoading: true }));

    it('renders the skeleton loader', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
    });
  });

  describe('when there are no issues', () => {
    beforeEach(() => mountComponent({ issues: [] }));

    it('renders the empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });
  });

  describe('when there are issues', () => {
    beforeEach(() => mountComponent());

    it('renders each issue', () => {
      expect(findIssuesData()).toEqual(asViewModel);
    });
  });

  describe('tracking', () => {
    const firstIssue = asViewModel[0];
    let eventSpy;

    beforeEach(() => {
      eventSpy = jest.spyOn(Tracking, 'event');
      mountComponent();
    });

    it('tracks when mounted', () => {
      expect(eventSpy).toHaveBeenCalledWith(undefined, TrackingActions.COMING_SOON_REQUESTED, {});
    });

    it('tracks when an issue title link is clicked', () => {
      eventSpy.mockClear();

      findIssueTitleLink().vm.$emit('click');

      expect(eventSpy).toHaveBeenCalledWith(undefined, TrackingActions.COMING_SOON_LIST, {
        label: firstIssue.title,
        value: firstIssue.iid,
      });
    });

    it('tracks when an issue id link is clicked', () => {
      eventSpy.mockClear();

      findIssueIdLink().vm.$emit('click');

      expect(eventSpy).toHaveBeenCalledWith(undefined, TrackingActions.COMING_SOON_LIST, {
        label: firstIssue.title,
        value: firstIssue.iid,
      });
    });
  });
});
