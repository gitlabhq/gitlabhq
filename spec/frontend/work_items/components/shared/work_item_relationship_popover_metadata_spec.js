import { GlAvatarsInline } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ItemMilestone from '~/issuable/components/issue_milestone.vue';
import WorkItemPopoverMetadata from '~/work_items/components/shared/work_item_relationship_popover_metadata.vue';
import { workItemTask } from '../../mock_data';

describe('WorkItemPopoverMetadata', () => {
  let wrapper;

  const mockMilestone = workItemTask.widgets.find(
    (widget) => widget.type === 'MILESTONE',
  ).milestone;
  const mockAssignees = workItemTask.widgets.find((widget) => widget.type === 'ASSIGNEES').assignees
    .nodes;

  const createComponent = () => {
    wrapper = shallowMountExtended(WorkItemPopoverMetadata, {
      propsData: {
        workItem: workItemTask,
        workItemFullPath: 'gitlab-org/gitlab-test',
      },
      scopedSlots: {
        'weight-metadata': `<div data-testid="weight-metadata-slot">Test weight metada</div>`,
        'additional-metadata': `<div data-testid="additional-metadata-slot">Test metadata</div>`,
      },
    });
  };

  const findItemMilestone = () => wrapper.findComponent(ItemMilestone);
  const findMetadataSlot = () => wrapper.findByTestId('additional-metadata-slot');
  const findWeightMetadataSlot = () => wrapper.findByTestId('weight-metadata-slot');
  const findAvatars = () => wrapper.findComponent(GlAvatarsInline);

  beforeEach(() => {
    createComponent();
  });

  it('renders scoped slot contents', () => {
    expect(findWeightMetadataSlot().text()).toBe('Test weight metada');
    expect(findMetadataSlot().text()).toBe('Test metadata');
  });

  it('renders work item milestone', () => {
    expect(findItemMilestone().exists()).toBe(true);
    expect(findItemMilestone().props('milestone')).toEqual(mockMilestone);
  });

  it('renders avatars for assignees', () => {
    expect(findAvatars().exists()).toBe(true);
    expect(findAvatars().props()).toMatchObject({
      avatars: mockAssignees,
      maxVisible: 3,
      avatarSize: 16,
      collapsed: true,
      badgeSrOnlyText: '',
      badgeTooltipProp: 'name',
      badgeTooltipMaxChars: null,
    });
  });
});
