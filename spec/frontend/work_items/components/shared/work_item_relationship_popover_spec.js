import { GlPopover, GlLoadingIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createMockDirective } from 'helpers/vue_mock_directive';
import WorkItemRelationshipPopover from '~/work_items/components/shared/work_item_relationship_popover.vue';
import { mockLinkedItems } from '../../mock_data';

describe('WorkItemRelationshipPopover', () => {
  let wrapper;

  const linkedItems = mockLinkedItems.linkedItems.nodes;
  const linkedItemsAboveLimit = [
    ...mockLinkedItems.linkedItems.nodes,
    {
      linkId: 'gid://gitlab/WorkItems::RelatedWorkItemLink/11',
      linkType: 'blocks',
      workItem: {
        id: 'gid://gitlab/WorkItem/648',
        iid: '57',
        confidential: true,
        workItemType: {
          id: 'gid://gitlab/WorkItems::Type/6',
          name: 'Objective',
          iconName: 'issue-type-objective',
          __typename: 'WorkItemType',
        },
        namespace: {
          id: 'gid://gitlab/Group/1',
          fullPath: 'test-project-path',
          __typename: 'Namespace',
        },
        reference: 'test-project-path#57',
        title: 'Multilevel Objective 3',
        state: 'OPEN',
        createdAt: '2023-03-28T10:50:16Z',
        closedAt: null,
        webUrl: '/gitlab-org/gitlab-test/-/work_items/57',
        widgets: [],
        __typename: 'WorkItem',
      },
      __typename: 'LinkedWorkItemType',
    },
  ];
  const closedChildLinkItem = {
    linkId: 'gid://gitlab/WorkItems::RelatedWorkItemLink/11',
    linkType: 'blocks',
    workItemState: 'CLOSED',
    workItem: {
      id: 'gid://gitlab/WorkItem/649',
      iid: '59',
      confidential: true,
      workItemType: {
        id: 'gid://gitlab/WorkItems::Type/8',
        name: 'Objective',
        iconName: 'issue-type-objective',
        __typename: 'WorkItemType',
      },
      namespace: {
        id: 'gid://gitlab/Group/1',
        fullPath: 'test-project-path',
        __typename: 'Namespace',
      },
      reference: 'test-project-path#57',
      title: 'Multilevel Objective 4',
      state: 'CLOSED',
      createdAt: '2023-03-28T10:50:16Z',
      closedAt: null,
      webUrl: '/gitlab-org/gitlab-test/-/work_items/57',
      widgets: [],
      __typename: 'WorkItem',
    },
    __typename: 'LinkedWorkItemType',
  };
  const linkedItemsWithClosedItem = [closedChildLinkItem, ...mockLinkedItems.linkedItems.nodes];
  const target = 'blocking-icon';
  const workItemWebUrl = '/gitlab-org/gitlab-test/-/work_items/1';

  const createComponent = ({ linkedWorkItems = linkedItems, loading = false } = {}) => {
    wrapper = shallowMountExtended(WorkItemRelationshipPopover, {
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
      propsData: {
        linkedWorkItems,
        title: 'Blocking',
        target,
        workItemFullPath: 'gitlab-org/gitlab-test',
        workItemWebUrl,
        workItemType: 'Task',
        loading,
      },
    });
  };

  const findPopover = () => wrapper.findComponent(GlPopover);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findMoreRelatedItemsLink = () => wrapper.findByTestId('more-related-items-link');

  beforeEach(() => {
    createComponent();
  });

  it('displays relationship popover on hover and focus', () => {
    expect(findPopover().exists()).toBe(true);
    expect(findPopover().props('triggers')).toBe('hover focus');
    expect(findPopover().props('target')).toBe(target);
  });

  it('displays loading icon if loading prop = true', () => {
    createComponent({ loading: true });
    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('displays linked items within the popover', () => {
    linkedItems.forEach((item) => {
      expect(findPopover().text()).toContain(item.workItem.title);
    });
  });

  it('does not display closed linked items within the popover', () => {
    createComponent({ linkedWorkItems: linkedItemsWithClosedItem });
    expect(findPopover().text()).not.toContain(closedChildLinkItem.workItem.title);
  });

  it('truncates linked items if the default display limit of 3 is exceeded', () => {
    createComponent({ linkedWorkItems: linkedItemsAboveLimit });
    expect(findMoreRelatedItemsLink().exists()).toBe(true);
    expect(findMoreRelatedItemsLink().attributes('href')).toBe(`${workItemWebUrl}#linkeditems`);
  });
});
