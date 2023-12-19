import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import MRPopover from '~/issuable/popover/components/mr_popover.vue';
import mergeRequestQuery from '~/issuable/popover/queries/merge_request.query.graphql';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';

describe('MR Popover', () => {
  let wrapper;

  Vue.use(VueApollo);

  const mrQueryResponse = {
    data: {
      project: {
        __typename: 'Project',
        id: '1',
        mergeRequest: {
          __typename: 'Merge Request',
          id: 'gid://gitlab/Merge_Request/1',
          createdAt: '2020-07-01T04:08:01Z',
          state: 'opened',
          title: 'MR title',
          headPipeline: {
            id: '1',
            detailedStatus: {
              id: '1',
              icon: 'status_success',
              group: 'success',
            },
          },
        },
      },
    },
  };

  const mrQueryResponseWithoutDetailedStatus = {
    data: {
      project: {
        __typename: 'Project',
        id: '1',
        mergeRequest: {
          __typename: 'Merge Request',
          id: 'gid://gitlab/Merge_Request/1',
          createdAt: '2020-07-01T04:08:01Z',
          state: 'opened',
          title: 'MR title',
          headPipeline: {
            id: '1',
            detailedStatus: null,
          },
        },
      },
    },
  };

  const mountComponent = ({
    queryResponse = jest.fn().mockResolvedValue(mrQueryResponse),
  } = {}) => {
    wrapper = shallowMount(MRPopover, {
      apolloProvider: createMockApollo([[mergeRequestQuery, queryResponse]]),
      propsData: {
        target: document.createElement('a'),
        namespacePath: 'foo/bar',
        iid: '1',
        cachedTitle: 'Cached Title',
      },
    });
  };

  it('shows skeleton-loader while apollo is loading', () => {
    mountComponent();

    expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
  });

  describe('when loaded', () => {
    beforeEach(() => {
      mountComponent();
      return waitForPromises();
    });

    it('shows opened time', () => {
      expect(wrapper.text()).toContain('Opened 4 days ago');
    });

    it('shows title', () => {
      expect(wrapper.find('h5').text()).toBe(mrQueryResponse.data.project.mergeRequest.title);
    });

    it('shows reference', () => {
      expect(wrapper.text()).toContain('foo/bar!1');
    });

    it('shows CI Icon if there is pipeline data', () => {
      expect(wrapper.findComponent(CiIcon).exists()).toBe(true);
    });
  });

  describe('without detailed status', () => {
    beforeEach(() => {
      mountComponent({
        queryResponse: jest.fn().mockResolvedValue(mrQueryResponseWithoutDetailedStatus),
      });
      return waitForPromises();
    });

    it('does not show CI icon if there is no pipeline data', () => {
      expect(wrapper.findComponent(CiIcon).exists()).toBe(false);
    });
  });
});
