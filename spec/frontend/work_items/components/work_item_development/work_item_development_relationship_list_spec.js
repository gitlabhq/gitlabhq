import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { workItemDevelopmentFragmentResponse } from 'jest/work_items/mock_data';
import WorkItemDevelopmentRelationshipList from '~/work_items/components/work_item_development/work_item_development_relationship_list.vue';

describe('WorkItemDevelopmentRelationshipList', () => {
  let wrapper;

  const devWidgetWithLessNumberOfItems = {
    ...workItemDevelopmentFragmentResponse(),
    closingMergeRequests: {
      nodes: [workItemDevelopmentFragmentResponse().closingMergeRequests.nodes[0]],
      __typename: 'WorkItemClosingMergeRequestConnection',
    },
  };

  const createComponent = ({ workItemDevWidget = workItemDevelopmentFragmentResponse() } = {}) => {
    wrapper = shallowMountExtended(WorkItemDevelopmentRelationshipList, {
      propsData: {
        workItemDevWidget,
      },
    });
  };

  const findDevList = () => wrapper.findByTestId('work-item-dev-items-list');
  const findShowMoreButton = () => wrapper.findComponent(GlButton);

  describe('Default', () => {
    it('should show the relationship list', () => {
      createComponent();
      expect(findDevList().exists()).toBe(true);
    });

    it('should render the more button when the number of items are more than 3', () => {
      createComponent();
      expect(findShowMoreButton().exists()).toBe(true);
    });

    it('should not render the more button when the number of items are more than 3', () => {
      createComponent({ workItemDevWidget: devWidgetWithLessNumberOfItems });
      expect(findShowMoreButton().exists()).toBe(false);
    });
  });
});
