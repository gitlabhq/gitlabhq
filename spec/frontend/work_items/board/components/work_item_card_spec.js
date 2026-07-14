import { GlLabel, GlTruncate } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { visitUrl } from '~/lib/utils/url_utility';
import WorkItemCard from '~/work_items/board/components/work_item_card.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import IssuableAssignees from '~/issuable/components/issue_assignees.vue';
import IssueMilestone from '~/issuable/components/issue_milestone.vue';
import IssueDueDate from '~/boards/components/issue_due_date.vue';
import WorkItemRelationshipIcons from '~/work_items/components/shared/work_item_relationship_icons.vue';
import WorkItemParentMetadata from '~/work_items/components/shared/work_item_parent_metadata.vue';
import {
  mockAssignees,
  mockLabels,
  mockStatus,
  mockMilestone,
  buildWorkItemNode,
  buildAssigneesWidget,
  buildLabelsWidget,
  buildStatusWidget,
  buildMilestoneWidget,
  buildStartAndDueDateWidget,
  buildWeightWidget,
  buildIterationWidget,
  buildHealthStatusWidget,
  buildLinkedItemsWidget,
  buildHierarchyWidget,
  mockParent,
} from '../mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

const buildItem = (overrides = {}) => buildWorkItemNode(1, overrides);

describe('WorkItemCard', () => {
  let wrapper;

  const findLink = () => wrapper.findByTestId('work-item-link');
  const findTitle = () => wrapper.findComponent(GlTruncate);
  const findReference = () => wrapper.findByTestId('work-item-reference');
  const findTypeIcon = () => wrapper.findComponent(WorkItemTypeIcon);
  const findLabels = () => wrapper.findAllComponents(GlLabel);
  const findAssigneesComponent = () => wrapper.findComponent(IssuableAssignees);
  const findStatusBadge = () => wrapper.findComponent({ name: 'WorkItemStatusBadge' });
  const findMetadataRow = () => wrapper.findByTestId('work-item-metadata');
  const findMilestone = () => wrapper.findComponent(IssueMilestone);
  const findDueDate = () => wrapper.findComponent(IssueDueDate);
  const findWeight = () => wrapper.findByTestId('work-item-weight');
  const findIteration = () => wrapper.findByTestId('work-item-iteration');
  const findHealthStatus = () => wrapper.findByTestId('work-item-health-status');
  const findParent = () => wrapper.findComponent(WorkItemParentMetadata);
  const findRelationshipIcons = () => wrapper.findComponent(WorkItemRelationshipIcons);

  const stubFrom = (name, props = []) => ({ name, props, template: '<div />' });

  const findCard = () => wrapper.findByTestId('work-item-board-card');

  const createComponent = ({
    item = buildItem(),
    hiddenMetadataKeys = [],
    rootPageFullPath = '',
    activeItem = null,
    detailPanelEnabled = true,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemCard, {
      propsData: { item, hiddenMetadataKeys, rootPageFullPath, activeItem, detailPanelEnabled },
      stubs: {
        WorkItemStatusBadge: stubFrom('WorkItemStatusBadge', ['item']),
        IssueWeight: stubFrom('IssueWeight'),
        IssueIteration: stubFrom('IssueIteration'),
        IssueHealthStatus: {
          name: 'IssueHealthStatus',
          props: {
            healthStatus: { default: '' },
            displayAsText: { type: Boolean, default: false },
            textSize: { default: '' },
          },
          template: '<div />',
        },
      },
    });
  };

  describe('link', () => {
    it('links to the item webPath', () => {
      createComponent({ item: buildItem({ webPath: '/some/path/-/issues/42' }) });

      expect(findLink().attributes('href')).toBe('/some/path/-/issues/42');
    });
  });

  describe('when selecting a card', () => {
    it('emits the `set-active-item` event with the selected item', async () => {
      const item = buildItem();
      createComponent({ item });

      await findLink().trigger('click');

      expect(wrapper.emitted('set-active-item')).toEqual([[item]]);
    });

    it('when already active, emits the `card-select` event with null', async () => {
      const item = buildItem();
      createComponent({ item, activeItem: item });

      await findLink().trigger('click');

      expect(wrapper.emitted('set-active-item')).toEqual([[null]]);
    });

    it('applies the active class when the card matches the active item', () => {
      const item = buildItem();
      createComponent({ item, activeItem: item });

      expect(findCard().classes()).toContain('is-active');
    });

    it('navigates to the detail work item page if the side panel is disabled', async () => {
      createComponent({
        detailPanelEnabled: false,
        item: buildItem({ webPath: '/group/project/-/work_items/1' }),
      });

      await findLink().trigger('click');

      expect(wrapper.emitted('set-active-item')).toBeUndefined();
      expect(visitUrl).toHaveBeenCalledWith('/group/project/-/work_items/1');
    });
  });

  describe('title', () => {
    it('renders the title via GlTruncate with a tooltip', () => {
      createComponent();

      expect(findTitle().props()).toMatchObject({
        text: 'Work item 1',
        withTooltip: true,
      });
    });
  });

  describe('reference', () => {
    it('renders the full reference when the item is in a different namespace', () => {
      createComponent({ rootPageFullPath: 'group/other-project' });

      expect(findReference().text()).toBe('group/project#1');
    });

    it('renders the short reference when the item is in the board namespace', () => {
      createComponent({ rootPageFullPath: 'group/project' });

      expect(findReference().text()).toBe('#1');
    });
  });

  describe('work item type icon', () => {
    it('renders the type icon when workItemType is set', () => {
      createComponent();

      expect(findTypeIcon().props()).toMatchObject({
        workItemType: 'Issue',
        typeIconName: 'issue-type-issue',
      });
    });

    it('does not render the type icon when workItemType is null', () => {
      createComponent({ item: buildItem({ workItemType: null }) });

      expect(findTypeIcon().exists()).toBe(false);
    });
  });

  describe('labels', () => {
    it('renders one GlLabel per label in the LABELS widget', () => {
      createComponent({ item: buildItem({ widgets: [buildLabelsWidget()] }) });

      expect(findLabels()).toHaveLength(mockLabels.length);
      expect(findLabels().at(0).props()).toMatchObject({
        backgroundColor: mockLabels[0].color,
        title: mockLabels[0].title,
        description: mockLabels[0].description,
      });
    });

    it('renders no labels when the widget is absent', () => {
      createComponent();

      expect(findLabels()).toHaveLength(0);
    });

    it('renders no labels when the widget has no label nodes', () => {
      createComponent({
        item: buildItem({
          widgets: [{ __typename: 'WorkItemWidgetLabels', type: 'LABELS', labels: null }],
        }),
      });

      expect(findLabels()).toHaveLength(0);
    });
  });

  describe('assignees', () => {
    it('renders IssuableAssignees with the assignees from the widget', () => {
      createComponent({ item: buildItem({ widgets: [buildAssigneesWidget()] }) });

      expect(findAssigneesComponent().props()).toMatchObject({
        assignees: mockAssignees,
        iconSize: 16,
        maxVisible: 3,
      });
    });

    it('does not render IssuableAssignees when the widget is absent', () => {
      createComponent();

      expect(findAssigneesComponent().exists()).toBe(false);
    });

    it('does not render IssuableAssignees when the widget has no assignees', () => {
      createComponent({ item: buildItem({ widgets: [buildAssigneesWidget([])] }) });

      expect(findAssigneesComponent().exists()).toBe(false);
    });
  });

  describe('status badge', () => {
    it('renders the WorkItemStatusBadge with the status from the widget', () => {
      createComponent({ item: buildItem({ widgets: [buildStatusWidget()] }) });

      expect(findStatusBadge().exists()).toBe(true);
      expect(findStatusBadge().props('item')).toEqual(mockStatus);
    });

    it('does not render the status badge when the widget is absent', () => {
      createComponent();

      expect(findStatusBadge().exists()).toBe(false);
    });

    it('does not render the status badge when the widget has no status', () => {
      createComponent({
        item: buildItem({
          widgets: [{ __typename: 'WorkItemWidgetStatus', type: 'STATUS', status: null }],
        }),
      });

      expect(findStatusBadge().exists()).toBe(false);
    });
  });

  describe('footer', () => {
    const findFooter = () => wrapper.findByTestId('work-item-footer');

    it('is not rendered when there are no assignees and no status', () => {
      createComponent();

      expect(findFooter().exists()).toBe(false);
    });

    it('is rendered when only assignees are present', () => {
      createComponent({ item: buildItem({ widgets: [buildAssigneesWidget()] }) });

      expect(findFooter().exists()).toBe(true);
      expect(findAssigneesComponent().exists()).toBe(true);
      expect(findStatusBadge().exists()).toBe(false);
    });

    it('is rendered when only status is present', () => {
      createComponent({ item: buildItem({ widgets: [buildStatusWidget()] }) });

      expect(findFooter().exists()).toBe(true);
      expect(findAssigneesComponent().exists()).toBe(false);
      expect(findStatusBadge().exists()).toBe(true);
    });

    it('renders the health status in the footer using the list-view text style', () => {
      createComponent({ item: buildItem({ widgets: [buildHealthStatusWidget()] }) });

      expect(findFooter().exists()).toBe(true);
      expect(findHealthStatus().exists()).toBe(true);
      expect(findHealthStatus().props()).toMatchObject({
        displayAsText: true,
        textSize: 'sm',
      });
    });
  });

  describe('metadata row', () => {
    it('is always rendered because it holds the reference', () => {
      createComponent();

      expect(findMetadataRow().exists()).toBe(true);
      expect(findMetadataRow().find('[data-testid="work-item-reference"]').exists()).toBe(true);
    });

    it('renders the milestone from the MILESTONE widget', () => {
      createComponent({ item: buildItem({ widgets: [buildMilestoneWidget()] }) });

      expect(findMilestone().props('milestone')).toEqual(mockMilestone);
    });

    it('renders the due date from the START_AND_DUE_DATE widget', () => {
      createComponent({
        item: buildItem({ widgets: [buildStartAndDueDateWidget({ dueDate: '2026-03-01' })] }),
      });

      expect(findDueDate().props('date')).toBe('2026-03-01');
    });

    it('does not render the due date when the widget has no due date', () => {
      createComponent({
        item: buildItem({ widgets: [buildStartAndDueDateWidget({ dueDate: null })] }),
      });

      expect(findDueDate().exists()).toBe(false);
    });

    it('renders the weight from the WEIGHT widget', () => {
      createComponent({ item: buildItem({ widgets: [buildWeightWidget(3)] }) });

      expect(findWeight().exists()).toBe(true);
    });

    it('renders the iteration from the ITERATION widget', () => {
      createComponent({ item: buildItem({ widgets: [buildIterationWidget()] }) });

      expect(findIteration().exists()).toBe(true);
    });

    it('renders the parent from the HIERARCHY widget', () => {
      createComponent({ item: buildItem({ widgets: [buildHierarchyWidget()] }) });

      expect(findParent().props('parent')).toEqual(mockParent);
    });

    it('does not render the parent when the widget has no parent', () => {
      createComponent({ item: buildItem({ widgets: [buildHierarchyWidget(null)] }) });

      expect(findParent().exists()).toBe(false);
    });
  });

  describe('relationship icons', () => {
    it('renders relationship icons when the item is blocking other items', () => {
      createComponent({
        item: buildItem({ widgets: [buildLinkedItemsWidget({ blockingCount: 2 })] }),
      });

      expect(findRelationshipIcons().props()).toMatchObject({
        blockingCount: 2,
        blockedByCount: 0,
      });
    });

    it('renders relationship icons when the item is blocked by other items', () => {
      createComponent({
        item: buildItem({ widgets: [buildLinkedItemsWidget({ blockedByCount: 1 })] }),
      });

      expect(findRelationshipIcons().exists()).toBe(true);
    });

    it('does not render relationship icons when there are no blocking relationships', () => {
      createComponent({ item: buildItem({ widgets: [buildLinkedItemsWidget()] }) });

      expect(findRelationshipIcons().exists()).toBe(false);
    });
  });

  describe('hidden metadata keys', () => {
    const findFooter = () => wrapper.findByTestId('work-item-footer');

    it('hides labels when "labels" is in hiddenMetadataKeys', () => {
      createComponent({
        item: buildItem({ widgets: [buildLabelsWidget()] }),
        hiddenMetadataKeys: ['labels'],
      });

      expect(findLabels()).toHaveLength(0);
    });

    it('hides assignees when "assignee" is in hiddenMetadataKeys', () => {
      createComponent({
        item: buildItem({ widgets: [buildAssigneesWidget()] }),
        hiddenMetadataKeys: ['assignee'],
      });

      expect(findAssigneesComponent().exists()).toBe(false);
    });

    it('hides the status badge when "status" is in hiddenMetadataKeys', () => {
      createComponent({
        item: buildItem({ widgets: [buildStatusWidget()] }),
        hiddenMetadataKeys: ['status'],
      });

      expect(findStatusBadge().exists()).toBe(false);
    });

    it('hides the milestone when "milestone" is in hiddenMetadataKeys', () => {
      createComponent({
        item: buildItem({ widgets: [buildMilestoneWidget()] }),
        hiddenMetadataKeys: ['milestone'],
      });

      expect(findMilestone().exists()).toBe(false);
    });

    it('hides the due date when "dates" is in hiddenMetadataKeys', () => {
      createComponent({
        item: buildItem({ widgets: [buildStartAndDueDateWidget()] }),
        hiddenMetadataKeys: ['dates'],
      });

      expect(findDueDate().exists()).toBe(false);
    });

    it('hides the weight when "weight" is in hiddenMetadataKeys', () => {
      createComponent({
        item: buildItem({ widgets: [buildWeightWidget()] }),
        hiddenMetadataKeys: ['weight'],
      });

      expect(findWeight().exists()).toBe(false);
    });

    it('hides the iteration when "iteration" is in hiddenMetadataKeys', () => {
      createComponent({
        item: buildItem({ widgets: [buildIterationWidget()] }),
        hiddenMetadataKeys: ['iteration'],
      });

      expect(findIteration().exists()).toBe(false);
    });

    it('hides the health status when "health" is in hiddenMetadataKeys', () => {
      createComponent({
        item: buildItem({ widgets: [buildHealthStatusWidget()] }),
        hiddenMetadataKeys: ['health'],
      });

      expect(findHealthStatus().exists()).toBe(false);
    });

    it('hides the relationship icons when "blocked" is in hiddenMetadataKeys', () => {
      createComponent({
        item: buildItem({ widgets: [buildLinkedItemsWidget({ blockingCount: 2 })] }),
        hiddenMetadataKeys: ['blocked'],
      });

      expect(findRelationshipIcons().exists()).toBe(false);
    });

    it('hides the parent when "parent" is in hiddenMetadataKeys', () => {
      createComponent({
        item: buildItem({ widgets: [buildHierarchyWidget()] }),
        hiddenMetadataKeys: ['parent'],
      });

      expect(findParent().exists()).toBe(false);
    });

    it('hides the footer when all footer metadata is hidden', () => {
      createComponent({
        item: buildItem({
          widgets: [
            buildAssigneesWidget(),
            buildStatusWidget(),
            buildHealthStatusWidget(),
            buildLinkedItemsWidget({ blockingCount: 1 }),
          ],
        }),
        hiddenMetadataKeys: ['assignee', 'status', 'health', 'blocked'],
      });

      expect(findFooter().exists()).toBe(false);
    });
  });
});
