import { GlIcon, GlLabel, GlAvatarsInline } from '@gitlab/ui';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import ItemMilestone from '~/issuable/components/issue_milestone.vue';
import WorkItemLinkChildMetadata from '~/work_items/components/work_item_links/work_item_link_child_metadata.vue';

import { mockMilestone, mockAssignees, mockLabels } from '../../mock_data';

describe('WorkItemLinkChildMetadata', () => {
  let wrapper;

  const createComponent = ({
    allowsScopedLabels = true,
    progress = 10,
    milestone = mockMilestone,
    assignees = mockAssignees,
    labels = mockLabels,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemLinkChildMetadata, {
      propsData: {
        allowsScopedLabels,
        progress,
        milestone,
        assignees,
        labels,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders item progress', () => {
    const progressEl = wrapper.findByTestId('item-progress');

    expect(progressEl.exists()).toBe(true);
    expect(progressEl.attributes('title')).toBe('Progress');
    expect(progressEl.text().trim()).toBe('10%');
    expect(progressEl.findComponent(GlIcon).props('name')).toBe('progress');
  });

  it('renders item milestone', () => {
    const milestoneLink = wrapper.findComponent(ItemMilestone);

    expect(milestoneLink.exists()).toBe(true);
    expect(milestoneLink.props('milestone')).toEqual(mockMilestone);
  });

  it('renders avatars for assignees', () => {
    const avatars = wrapper.findComponent(GlAvatarsInline);

    expect(avatars.exists()).toBe(true);
    expect(avatars.props()).toMatchObject({
      avatars: mockAssignees,
      collapsed: true,
      maxVisible: 2,
      avatarSize: 24,
      badgeTooltipProp: 'name',
      badgeSrOnlyText: '',
    });
  });

  it('renders labels', () => {
    const labels = wrapper.findAllComponents(GlLabel);
    const mockLabel = mockLabels[0];

    expect(labels).toHaveLength(mockLabels.length);
    expect(labels.at(0).props()).toMatchObject({
      title: mockLabel.title,
      backgroundColor: mockLabel.color,
      description: mockLabel.description,
      scoped: false,
    });
    expect(labels.at(1).props('scoped')).toBe(true); // Second label is scoped
  });
});
