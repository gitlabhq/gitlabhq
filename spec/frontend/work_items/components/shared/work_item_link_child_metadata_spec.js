import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import ItemMilestone from '~/issuable/components/issue_milestone.vue';
import WorkItemLinkChildMetadata from '~/work_items/components/shared/work_item_link_child_metadata.vue';

import { workItemObjectiveMetadataWidgets } from '../../mock_data';

describe('WorkItemLinkChildMetadata', () => {
  const { MILESTONE } = workItemObjectiveMetadataWidgets;
  const mockMilestone = MILESTONE.milestone;

  let wrapper;

  const createComponent = ({ metadataWidgets = workItemObjectiveMetadataWidgets } = {}) => {
    wrapper = shallowMountExtended(WorkItemLinkChildMetadata, {
      propsData: {
        iid: '1',
        reference: 'test-project-path#1',
        metadataWidgets,
      },
      scopedSlots: {
        'left-metadata': `<div data-testid="left-metadata-slot">Foo</div>`,
        'right-metadata': `<div data-testid="right-metadata-slot">Bar</div>`,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders scoped slot contents', () => {
    expect(wrapper.findByTestId('left-metadata-slot').text()).toBe('Foo');
    expect(wrapper.findByTestId('right-metadata-slot').text()).toBe('Bar');
  });

  it('renders item milestone', () => {
    const milestoneLink = wrapper.findComponent(ItemMilestone);

    expect(milestoneLink.exists()).toBe(true);
    expect(milestoneLink.props('milestone')).toEqual(mockMilestone);
  });
});
