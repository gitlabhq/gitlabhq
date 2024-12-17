import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { workItemDevelopmentFragmentResponse } from 'jest/work_items/mock_data';
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

  describe('Default', () => {
    it('should show the relationship list', () => {
      createComponent();
      expect(findDevList().exists()).toBe(true);
    });
  });
});
