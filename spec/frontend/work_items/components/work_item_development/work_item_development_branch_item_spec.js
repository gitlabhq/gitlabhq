import { GlLink, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { workItemRelatedBranchNodes } from 'jest/work_items/mock_data';
import WorkItemDevelopmentBranchItem from '~/work_items/components/work_item_development/work_item_development_branch_item.vue';
import { visitUrl } from '~/lib/utils/url_utility';
import { createBranchMRApiPathHelper } from '~/work_items/utils';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));
jest.mock('~/work_items/utils', () => ({
  createBranchMRApiPathHelper: {
    createMR: jest.fn(),
  },
}));

describe('WorkItemDevelopmentBranchItem', () => {
  let wrapper;

  const branchNode = workItemRelatedBranchNodes[0];
  const workItemFullPath = 'flightjs/Flight';
  const workItemIid = '1';

  const createComponent = ({ branch = branchNode, canCreateMergeRequest = true } = {}) => {
    wrapper = shallowMount(WorkItemDevelopmentBranchItem, {
      propsData: {
        itemContent: branch,
        canCreateMergeRequest,
        workItemFullPath,
        workItemIid,
      },
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findLink = () => wrapper.findComponent(GlLink);
  const findCreateMRAction = () => wrapper.find('[data-testid="branch-create-merge-request"]');

  it('should render the comparePath and name with icon', () => {
    createComponent();
    expect(findIcon().exists()).toBe(true);
    expect(findIcon().props('name')).toBe('branch');
    expect(findIcon().attributes('title')).toBe('Branch');
    expect(findLink().attributes('href')).toBe(branchNode.comparePath);
    expect(findLink().text()).toBe(branchNode.name);
  });

  describe('dropdown actions', () => {
    describe('when user can create a merge request', () => {
      beforeEach(() => {
        createComponent({ canCreateMergeRequest: true });
        createBranchMRApiPathHelper.createMR.mockReturnValue(
          '/fullPath/-/merge_requests/new?merge_request%5Bissue_iid%5D=1&merge_request%5Bsource_branch%5D=branch_name',
        );
      });

      afterEach(() => {
        jest.clearAllMocks();
      });

      it('shows the create merge request action', () => {
        expect(findCreateMRAction().exists()).toBe(true);
      });

      it('navigates to the correct URL when create merge request is clicked', async () => {
        await findCreateMRAction().vm.$emit('action');

        expect(createBranchMRApiPathHelper.createMR).toHaveBeenCalledWith({
          fullPath: workItemFullPath,
          workItemIid,
          sourceBranch: branchNode.name,
        });
        expect(visitUrl).toHaveBeenCalledWith(
          '/fullPath/-/merge_requests/new?merge_request%5Bissue_iid%5D=1&merge_request%5Bsource_branch%5D=branch_name',
        );
      });
    });
  });
});
