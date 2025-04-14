import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import StatusBadge from '~/merge_request_dashboard/components/status_badge.vue';

let wrapper;

const findStatusBadge = () => wrapper.findByTestId('merge-request-status-badge');

function createComponent({
  mergeRequest = { reviewers: { nodes: [] } },
  listId = 'waiting_for_assignee',
} = {}) {
  wrapper = shallowMountExtended(StatusBadge, {
    propsData: {
      mergeRequest,
      listId,
    },
  });
}

describe('Merge request status badge component', () => {
  afterEach(() => {
    window.gon = {};
  });

  it('renders badge', () => {
    window.gon = { current_user_id: 1 };

    createComponent({
      mergeRequest: {
        reviewers: {
          nodes: [
            {
              id: 'gid://gitlab/User/1',
              mergeRequestInteraction: { reviewState: 'REVIEWED' },
            },
          ],
        },
      },
    });

    expect(findStatusBadge().element).toMatchSnapshot();
  });

  it('renders badge when currentUser is a reviewer', () => {
    window.gon = { current_user_id: 1 };

    createComponent({
      mergeRequest: {
        reviewers: {
          nodes: [
            {
              id: 'gid://gitlab/User/1',
              mergeRequestInteraction: { reviewState: 'REQUESTED_CHANGES' },
            },
          ],
        },
      },
    });

    expect(findStatusBadge().element).toMatchSnapshot();
  });

  describe('ready to merge', () => {
    it('renders ready to merge badge when there is no failed merge checks', () => {
      createComponent({
        mergeRequest: {
          mergeabilityChecks: [{ status: 'SUCCESS' }],
        },
      });

      expect(findStatusBadge().text()).toBe('Ready to merge');
      expect(findStatusBadge().attributes('icon')).toBe('status-success');
    });

    it('renders normal status badge when there is failed merge checks', () => {
      createComponent({
        mergeRequest: {
          mergeabilityChecks: [{ status: 'FAILED' }],
          reviewers: { nodes: [] },
        },
        listId: 'assigned_to_you',
      });

      expect(findStatusBadge().text()).toBe('Reviewers needed');
    });
  });
});
