import { nextTick } from 'vue';
import { GlLabel, GlTruncate } from '@gitlab/ui';
import { resetHTMLFixture, setHTMLFixture } from 'helpers/fixtures';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { visitUrl } from '~/lib/utils/url_utility';
import WorkItemCard from '~/work_items/board/components/work_item_card.vue';
import { BOARD_CARD_LINK_CLASS, BOARD_CARD_LIST_CLASS } from '~/work_items/board/constants';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import IssuableAssignees from '~/issuable/components/issue_assignees.vue';
import IssueMilestone from '~/issuable/components/issue_milestone.vue';
import WorkItemDatesAttribute from '~/work_items/components/shared/work_item_dates_attribute.vue';
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
  const findTypeDescription = () => wrapper.findByTestId('work-item-type-description');
  const findTitle = () => wrapper.findComponent(GlTruncate);
  const findReference = () => wrapper.findByTestId('work-item-reference');
  const findTypeIcon = () => wrapper.findComponent(WorkItemTypeIcon);
  const findLabels = () => wrapper.findAllComponents(GlLabel);
  const findAssigneesComponent = () => wrapper.findComponent(IssuableAssignees);
  const findStatusBadge = () => wrapper.findComponent({ name: 'WorkItemStatusBadge' });
  const findMetadataRow = () => wrapper.findByTestId('work-item-metadata');
  const findMilestone = () => wrapper.findComponent(IssueMilestone);
  const findDates = () => wrapper.findComponent(WorkItemDatesAttribute);
  const findWeight = () => wrapper.findByTestId('work-item-weight');
  const findIteration = () => wrapper.findByTestId('work-item-iteration');
  const findHealthStatus = () => wrapper.findComponentByTestId('work-item-health-status');
  const findParent = () => wrapper.findComponent(WorkItemParentMetadata);
  const findRelationshipIcons = () => wrapper.findComponent(WorkItemRelationshipIcons);

  const stubFrom = (name, props = []) => ({ name, props, template: '<div />' });

  const findCard = () => wrapper.findByTestId('work-item-board-card');
  const findActionsMenu = () => wrapper.findComponentByTestId('card-actions-menu');
  const findActionItems = () => findActionsMenu().props('items');
  const findActionItem = (text) => findActionItems().find((item) => item.text === text);

  const createComponent = ({
    item = buildItem(),
    hiddenMetadataKeys = [],
    rootPageFullPath = '',
    activeItem = null,
    detailPanelEnabled = true,
    canReorder = false,
    isFirst = false,
    isLast = false,
    attachTo,
  } = {}) => {
    wrapper = shallowMountExtended(WorkItemCard, {
      attachTo,
      propsData: {
        item,
        hiddenMetadataKeys,
        rootPageFullPath,
        activeItem,
        detailPanelEnabled,
        canReorder,
        isFirst,
        isLast,
      },
      stubs: {
        WorkItemStatusBadge: stubFrom('WorkItemStatusBadge', ['item']),
        IssueWeight: stubFrom('IssueWeight'),
        WorkItemIterationAttribute: stubFrom('WorkItemIterationAttribute'),
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

    it('wraps only the title, so the metadata is not nested inside it', () => {
      createComponent();

      expect(findLink().findComponent(GlTruncate).exists()).toBe(true);
      expect(findLink().element.contains(findMetadataRow().element)).toBe(false);
    });

    it('sets the id the side panel focuses on close', () => {
      createComponent();

      expect(findLink().attributes('id')).toBe('listItem-group/1');
    });

    describe('when the item is from another namespace', () => {
      beforeEach(() => {
        createComponent({
          item: buildItem({
            namespace: {
              __typename: 'Project',
              id: 'gid://gitlab/Project/2',
              fullPath: 'other/project',
            },
          }),
        });
      });

      it('uses that namespace in the id', () => {
        expect(findLink().attributes('id')).toBe('listItem-other/project/1');
      });
    });
  });

  describe('screen reader description', () => {
    const describedByIds = () => findLink().attributes('aria-describedby').split(' ');

    it('describes the link with the work item type and the reference', () => {
      createComponent({ item: buildItem({ reference: 'group/project#42' }) });

      const [typeId, referenceId] = describedByIds();

      expect(findTypeDescription().attributes('id')).toBe(typeId);
      expect(findTypeDescription().text()).toBe('Issue');
      expect(findReference().attributes('id')).toBe(referenceId);
      expect(findReference().text()).toBe('group/project#42');
    });

    describe('when the item has no work item type', () => {
      it('describes the link with the reference alone', () => {
        createComponent({ item: buildItem({ workItemType: null }) });

        expect(findTypeDescription().exists()).toBe(false);
        expect(describedByIds()).toEqual([findReference().attributes('id')]);
      });
    });
  });

  describe('aria-current', () => {
    it('is not set when the card is not the active item', () => {
      createComponent();

      expect(findLink().attributes('aria-current')).toBeUndefined();
    });

    describe('when the card is the active item', () => {
      it('marks the link as current', () => {
        const item = buildItem();
        createComponent({ item, activeItem: item });

        expect(findLink().attributes('aria-current')).toBe('true');
      });
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

    it('applies the active background and border when the card matches the active item', () => {
      const item = buildItem();
      createComponent({ item, activeItem: item });

      expect(findCard().classes()).toEqual(
        expect.arrayContaining([
          '!gl-border-strong',
          '!gl-bg-neutral-100',
          'dark:!gl-bg-neutral-700',
        ]),
      );
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

  describe('keyboard navigation', () => {
    const otherCard = (testId) =>
      `<li><a class="${BOARD_CARD_LINK_CLASS}" href="#" data-testid="${testId}"></a></li>`;

    const findOtherCard = (testId) => document.querySelector(`[data-testid="${testId}"]`);

    const pressKey = (element, key, options = {}) => {
      const event = new KeyboardEvent('keydown', { key, cancelable: true, ...options });
      element.dispatchEvent(event);
      return event;
    };

    beforeEach(() => {
      setHTMLFixture(`
        <ul class="${BOARD_CARD_LIST_CLASS}">${otherCard('previous-column-card')}</ul>
        <ul class="${BOARD_CARD_LIST_CLASS}">
          ${otherCard('card-above')}
          ${otherCard('card-below')}
        </ul>
        <ul class="${BOARD_CARD_LIST_CLASS}">${otherCard('next-column-card')}</ul>
      `);
      // VTU1 replaces the attachTo element and VTU2 appends into it, so mount
      // detached and move the card in to get a valid ul > li on both.
      createComponent({ canReorder: true, attachTo: document.createElement('div') });
      findOtherCard('card-below').parentElement.before(wrapper.element);
      findLink().element.focus();
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it.each`
      key             | testId
      ${'ArrowDown'}  | ${'card-below'}
      ${'ArrowUp'}    | ${'card-above'}
      ${'ArrowLeft'}  | ${'previous-column-card'}
      ${'ArrowRight'} | ${'next-column-card'}
    `('moves focus to $testId on $key', ({ key, testId }) => {
      pressKey(findLink().element, key);

      expect(document.activeElement).toBe(findOtherCard(testId));
    });

    it.each(['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'])(
      'prevents the default %s scroll on the card link',
      (key) => {
        expect(pressKey(findLink().element, key).defaultPrevented).toBe(true);
      },
    );

    it('does not handle Shift+ArrowDown on the card link', () => {
      const event = pressKey(findLink().element, 'ArrowDown', { shiftKey: true });

      expect(event.defaultPrevented).toBe(false);
      expect(document.activeElement).toBe(findLink().element);
    });

    it('does not handle ArrowDown on the card actions menu', () => {
      const event = pressKey(findActionsMenu().element, 'ArrowDown');

      expect(event.defaultPrevented).toBe(false);
      expect(document.activeElement).toBe(findLink().element);
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
        iconVariant: 'subtle',
        showTooltipOnHover: true,
      });
    });

    it('keeps the type icon out of the tab order, so the title link is the first tab stop', () => {
      createComponent();

      expect(findTypeIcon().attributes('tabindex')).toBe('-1');
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
        scoped: false,
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

    describe('when the namespace allows scoped labels', () => {
      it('renders a scoped label as scoped', () => {
        const scopedLabel = { ...mockLabels[0], title: 'team::frontend' };
        createComponent({
          item: buildItem({
            widgets: [{ ...buildLabelsWidget([scopedLabel]), allowsScopedLabels: true }],
          }),
        });

        expect(findLabels().at(0).props('scoped')).toBe(true);
      });
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
      expect(findMilestone().classes()).toContain('!gl-max-w-28');
    });

    describe('dates', () => {
      it.each`
        case            | startDate       | dueDate
        ${'start only'} | ${'2026-02-01'} | ${null}
        ${'due only'}   | ${null}         | ${'2026-03-01'}
        ${'both dates'} | ${'2026-02-01'} | ${'2026-03-01'}
      `('renders the dates attribute when $case is set', ({ startDate, dueDate }) => {
        createComponent({
          item: buildItem({ widgets: [buildStartAndDueDateWidget({ startDate, dueDate })] }),
        });

        expect(findDates().props()).toMatchObject({ startDate, dueDate });
      });

      it('does not render the dates attribute when neither date is set', () => {
        createComponent({
          item: buildItem({
            widgets: [buildStartAndDueDateWidget({ startDate: null, dueDate: null })],
          }),
        });

        expect(findDates().exists()).toBe(false);
      });

      it.each`
        case        | closedAt
        ${'open'}   | ${null}
        ${'closed'} | ${'2026-01-02T00:00:00Z'}
      `('passes isClosed as $case', ({ closedAt }) => {
        createComponent({
          item: buildItem({ closedAt, widgets: [buildStartAndDueDateWidget()] }),
        });

        expect(findDates().props('isClosed')).toBe(Boolean(closedAt));
      });
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

    it('hides the dates attribute when "dates" is in hiddenMetadataKeys', () => {
      createComponent({
        item: buildItem({ widgets: [buildStartAndDueDateWidget()] }),
        hiddenMetadataKeys: ['dates'],
      });

      expect(findDates().exists()).toBe(false);
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

  describe('actions menu', () => {
    it('is not rendered when canReorder is false', () => {
      createComponent({ canReorder: false });

      expect(findActionsMenu().exists()).toBe(false);
    });

    it('is not rendered when the card is both first and last in the column', () => {
      createComponent({ canReorder: true, isFirst: true, isLast: true });

      expect(findActionsMenu().exists()).toBe(false);
    });

    it('renders both move actions in order, each with a direction icon', () => {
      createComponent({ canReorder: true });

      expect(findActionItems().map((item) => [item.text, item.icon])).toEqual([
        ['Move to start of list', 'arrow-up'],
        ['Move to end of list', 'arrow-down'],
      ]);
    });

    it('disables "Move to start of list" on the first card and "Move to end of list" on the last', () => {
      createComponent({ canReorder: true, isFirst: true, isLast: false });

      expect(findActionItem('Move to start of list').extraAttrs.disabled).toBe(true);
      expect(findActionItem('Move to end of list').extraAttrs.disabled).toBe(false);
    });

    it('emits move-to-start when "Move to start of list" is actioned', () => {
      createComponent({ canReorder: true });

      findActionItem('Move to start of list').action();

      expect(wrapper.emitted('move-to-start')).toEqual([[]]);
    });

    it('emits move-to-end when "Move to end of list" is actioned', () => {
      createComponent({ canReorder: true });

      findActionItem('Move to end of list').action();

      expect(wrapper.emitted('move-to-end')).toEqual([[]]);
    });

    describe('when opened', () => {
      beforeEach(async () => {
        createComponent({ canReorder: true });
        findActionsMenu().vm.$emit('shown');
        await nextTick();
      });

      it('stacks above the content of the next card', () => {
        expect(findActionsMenu().classes()).toContain('gl-z-2');
      });

      it('drops back to the card content level when closed', async () => {
        findActionsMenu().vm.$emit('hidden');
        await nextTick();

        expect(findActionsMenu().classes()).toContain('gl-z-1');
      });
    });
  });
});
