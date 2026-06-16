import { GlLabel, GlTruncate } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemCard from '~/work_items/board/components/work_item_card.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import IssuableAssignees from '~/issuable/components/issue_assignees.vue';
import {
  mockAssignees,
  mockLabels,
  mockStatus,
  buildWorkItemNode,
  buildAssigneesWidget,
  buildLabelsWidget,
  buildStatusWidget,
} from '../mock_data';

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

  const WorkItemStatusBadgeStub = {
    name: 'WorkItemStatusBadge',
    props: ['item'],
    template: '<div />',
  };

  const createComponent = ({ item = buildItem() } = {}) => {
    wrapper = shallowMountExtended(WorkItemCard, {
      propsData: { item },
      stubs: {
        WorkItemStatusBadge: WorkItemStatusBadgeStub,
      },
    });
  };

  describe('link', () => {
    it('links to the item webPath', () => {
      createComponent({ item: buildItem({ webPath: '/some/path/-/issues/42' }) });

      expect(findLink().attributes('href')).toBe('/some/path/-/issues/42');
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
    it('renders the item reference', () => {
      createComponent();

      expect(findReference().text()).toBe('group/project#1');
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
  });
});
