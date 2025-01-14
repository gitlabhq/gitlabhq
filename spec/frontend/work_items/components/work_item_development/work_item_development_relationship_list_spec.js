import { map } from 'lodash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  workItemDevelopmentFragmentResponse,
  workItemDevelopmentMRNodes,
} from 'jest/work_items/mock_data';
import WorkItemDevelopmentMrItem from '~/work_items/components/work_item_development/work_item_development_mr_item.vue';
import WorkItemDevelopmentRelationshipList from '~/work_items/components/work_item_development/work_item_development_relationship_list.vue';

describe('WorkItemDevelopmentRelationshipList', () => {
  let wrapper;

  const createComponent = ({ workItemDevWidget = workItemDevelopmentFragmentResponse() } = {}) => {
    wrapper = shallowMountExtended(WorkItemDevelopmentRelationshipList, {
      propsData: {
        workItemDevWidget,
      },
    });
  };

  const findDevList = () => wrapper.findByTestId('work-item-dev-items-list');
  const findAllMergeRequests = () => wrapper.findAllComponents(WorkItemDevelopmentMrItem);

  describe('Default', () => {
    it('should show the relationship list', () => {
      createComponent();
      expect(findDevList().exists()).toBe(true);
    });
  });

  it('deduplicates the closingMRs and relatedMRs on frontend', () => {
    createComponent({
      workItemDevWidget: workItemDevelopmentFragmentResponse({
        mrNodes: workItemDevelopmentMRNodes,
        willAutoCloseByMergeRequest: false,
        relatedMergeRequests: map(workItemDevelopmentMRNodes, 'mergeRequest'),
        branchNodes: [],
        featureFlagNodes: [],
      }),
    });

    expect(Number(findDevList().attributes('data-list-length'))).toEqual(
      workItemDevelopmentMRNodes.length,
    );
  });

  it('maintains the order for MRs on frontend as merged > open > closed', () => {
    const closedMergeRequest = workItemDevelopmentMRNodes[2];

    const mergedMergeRequest = workItemDevelopmentMRNodes[1];

    const openMergeRequest = workItemDevelopmentMRNodes[0];

    createComponent({
      workItemDevWidget: workItemDevelopmentFragmentResponse({
        mrNodes: [closedMergeRequest, mergedMergeRequest, openMergeRequest],
        willAutoCloseByMergeRequest: false,
        relatedMergeRequests: [],
        branchNodes: [],
        featureFlagNodes: [],
      }),
    });

    expect(findAllMergeRequests().length).toBe(3);

    expect(findAllMergeRequests().at(0).props('itemContent')).toEqual(
      expect.objectContaining({
        state: 'merged',
      }),
    );

    expect(findAllMergeRequests().at(1).props('itemContent')).toEqual(
      expect.objectContaining({
        state: 'opened',
      }),
    );

    expect(findAllMergeRequests().at(2).props('itemContent')).toEqual(
      expect.objectContaining({
        state: 'closed',
      }),
    );
  });
});
