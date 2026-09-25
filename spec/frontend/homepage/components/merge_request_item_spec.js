import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MergeRequestItem from '~/homepage/components/merge_request_item.vue';
import ApprovalCount from 'ee_else_ce/merge_requests/components/approval_count.vue';
import DiscussionsBadge from '~/merge_requests/list/components/discussions_badge.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import {
  buildMergeRequest,
  mergeRequestWithoutMetadata,
} from './mocks/merge_requests_widget_query_mocks';

describe('MergeRequestItem', () => {
  let wrapper;

  const findLink = () => wrapper.find('a');
  const findTime = () => wrapper.find('time');
  const findCiIcon = () => wrapper.findComponent(CiIcon);
  const findApprovalCount = () => wrapper.findComponent(ApprovalCount);
  const findDiscussionsBadge = () => wrapper.findComponent(DiscussionsBadge);

  const createComponent = ({ mergeRequest = buildMergeRequest(1) } = {}) => {
    wrapper = shallowMountExtended(MergeRequestItem, {
      propsData: { mergeRequest },
    });
  };

  describe('by default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('links to the merge request', () => {
      expect(findLink().attributes('href')).toBe('/acme/web-app/-/merge_requests/1');
    });

    it('renders the merge request title', () => {
      expect(wrapper.text()).toContain('Merge request 1');
    });

    it('renders the direct parent namespace and project name', () => {
      expect(wrapper.text()).toContain('Acme Corp / Web App');
    });

    it('renders the updated timestamp as a machine-readable time element', () => {
      expect(findTime().attributes('datetime')).toBe('2025-06-12T15:13:25Z');
      expect(findTime().text()).toContain('Updated');
    });

    // The date is the only thing allowed to give way when the row is short on space:
    // it truncates so the badges beside it are never clipped and the row never wraps
    // onto a fourth line.
    it('truncates the date rather than clipping the badges', () => {
      expect(findTime().classes()).toContain('gl-truncate');
      expect(findTime().attributes('title')).toContain('Updated');
    });

    it('emits click when the row is clicked', () => {
      findLink().element.addEventListener('click', (e) => e.preventDefault(), { once: true });

      findLink().trigger('click');

      expect(wrapper.emitted('click')).toHaveLength(1);
    });
  });

  describe('when the project is nested in a subgroup', () => {
    beforeEach(() => {
      createComponent({
        mergeRequest: buildMergeRequest(1, {
          project: {
            id: 'gid://gitlab/Project/1',
            name: 'project',
            namespace: {
              id: 'gid://gitlab/Group/2',
              name: 'subgroup',
              __typename: 'Namespace',
            },
            __typename: 'Project',
          },
        }),
      });
    });

    it('renders only the direct parent, not the full hierarchy', () => {
      expect(wrapper.text()).toContain('subgroup / project');
    });
  });

  describe('when the merge request has pipeline, approval and discussion data', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the pipeline status', () => {
      expect(findCiIcon().props('status')).toMatchObject({ icon: 'status_success' });
    });

    it('renders the approval count', () => {
      expect(findApprovalCount().exists()).toBe(true);
    });

    it('renders the discussions badge', () => {
      expect(findDiscussionsBadge().exists()).toBe(true);
    });
  });

  describe('when the merge request has no pipeline or discussions', () => {
    beforeEach(() => {
      createComponent({ mergeRequest: mergeRequestWithoutMetadata });
    });

    it('does not render the pipeline status', () => {
      expect(findCiIcon().exists()).toBe(false);
    });

    it('does not render the discussions badge', () => {
      expect(findDiscussionsBadge().exists()).toBe(false);
    });
  });
});
