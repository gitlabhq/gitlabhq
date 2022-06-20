import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import StatusBox from '~/issuable/components/status_box.vue';
import IssuePopover from '~/issuable/popover/components/issue_popover.vue';
import issueQuery from '~/issuable/popover/queries/issue.query.graphql';

describe('Issue Popover', () => {
  let wrapper;

  Vue.use(VueApollo);

  const issueQueryResponse = {
    data: {
      project: {
        __typename: 'Project',
        id: '1',
        issue: {
          __typename: 'Issue',
          id: 'gid://gitlab/Issue/1',
          createdAt: '2020-07-01T04:08:01Z',
          state: 'opened',
          title: 'Issue title',
        },
      },
    },
  };

  const mountComponent = ({
    queryResponse = jest.fn().mockResolvedValue(issueQueryResponse),
  } = {}) => {
    wrapper = shallowMount(IssuePopover, {
      apolloProvider: createMockApollo([[issueQuery, queryResponse]]),
      propsData: {
        target: document.createElement('a'),
        projectPath: 'foo/bar',
        iid: '1',
        cachedTitle: 'Cached title',
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('shows skeleton-loader while apollo is loading', () => {
    mountComponent();

    expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
  });

  describe('when loaded', () => {
    beforeEach(() => {
      mountComponent();
      return waitForPromises();
    });

    it('shows status badge', () => {
      expect(wrapper.findComponent(StatusBox).props()).toEqual({
        issuableType: 'issue',
        initialState: issueQueryResponse.data.project.issue.state,
      });
    });

    it('shows opened time', () => {
      expect(wrapper.text()).toContain('Opened 4 days ago');
    });

    it('shows title', () => {
      expect(wrapper.find('h5').text()).toBe(issueQueryResponse.data.project.issue.title);
    });

    it('shows reference', () => {
      expect(wrapper.text()).toContain('foo/bar#1');
    });
  });
});
