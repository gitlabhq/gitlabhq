import { GlLabel, GlTruncate } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import IssueAssignees from '~/issuable/components/issue_assignees.vue';
import IssuableMilestone from '~/vue_shared/issuable/list/components/issuable_milestone.vue';
import WorkItemTableCell from '~/work_items/table/components/work_item_table_cell.vue';
import {
  COLUMN_ASSIGNEES,
  COLUMN_CREATED_AT,
  COLUMN_DUE_DATE,
  COLUMN_HEALTH_STATUS,
  COLUMN_ITERATION,
  COLUMN_LABELS,
  COLUMN_MILESTONE,
  COLUMN_REFERENCE,
  COLUMN_START_DATE,
  COLUMN_STATUS,
  COLUMN_TITLE,
  COLUMN_WEIGHT,
} from '~/work_items/table/constants';
import {
  buildAssigneesWidget,
  buildHealthStatusWidget,
  buildIterationWidget,
  buildLabelsWidget,
  buildMilestoneWidget,
  buildStartAndDueDateWidget,
  buildStatusWidget,
  buildWeightWidget,
  buildWorkItemNode,
  mockAssignees,
  mockIteration,
  mockLabels,
  mockMilestone,
  mockStatus,
} from '../../board/mock_data';

const stubFrom = (name, props = []) => ({ name, props, template: '<div />' });

describe('WorkItemTableCell', () => {
  let wrapper;

  const findStatusBadge = () => wrapper.findComponent({ name: 'WorkItemStatusBadge' });
  const findIteration = () => wrapper.findComponent({ name: 'IssueIteration' });
  const findHealthStatus = () => wrapper.findComponent({ name: 'IssueHealthStatus' });
  const findAssignees = () => wrapper.findComponent(IssueAssignees);
  const findMilestone = () => wrapper.findComponent(IssuableMilestone);
  const findTruncatedText = () => wrapper.findComponent(GlTruncate);
  const findLabels = () => wrapper.findAllComponents(GlLabel);
  const findLabel = () => wrapper.findComponent(GlLabel);
  const findWeight = () => wrapper.findByTestId('cell-weight');
  const findStartDate = () => wrapper.findByTestId('cell-start-date');
  const findDueDate = () => wrapper.findByTestId('cell-due-date');

  const createComponent = ({ columnKey, item = buildWorkItemNode(1), ...options } = {}) => {
    wrapper = shallowMountExtended(WorkItemTableCell, {
      propsData: { columnKey, item, rootPageFullPath: 'group', ...options },
      stubs: {
        WorkItemStatusBadge: stubFrom('WorkItemStatusBadge', ['item']),
        IssueIteration: stubFrom('IssueIteration', ['iteration']),
        IssueHealthStatus: stubFrom('IssueHealthStatus', ['healthStatus']),
      },
    });
  };

  describe('reference column', () => {
    describe('when the item belongs to the table namespace', () => {
      beforeEach(() => {
        createComponent({
          columnKey: COLUMN_REFERENCE,
          item: buildWorkItemNode(1, { reference: 'group/project#1' }),
          rootPageFullPath: 'group/project',
        });
      });

      it('shortens the reference', () => {
        expect(findTruncatedText().props('text')).toBe('#1');
      });
    });

    describe('when the item belongs to another namespace', () => {
      beforeEach(() => {
        createComponent({
          columnKey: COLUMN_REFERENCE,
          item: buildWorkItemNode(1, { reference: 'group/other-project#1' }),
          rootPageFullPath: 'group/project',
        });
      });

      it('keeps the full reference', () => {
        expect(findTruncatedText().props('text')).toBe('group/other-project#1');
      });
    });
  });

  describe('status column', () => {
    describe('when the item has a status', () => {
      beforeEach(() => {
        createComponent({
          columnKey: COLUMN_STATUS,
          item: buildWorkItemNode(1, { widgets: [buildStatusWidget()] }),
        });
      });

      it('renders the status badge', () => {
        expect(findStatusBadge().props('item')).toEqual(mockStatus);
      });
    });
  });

  describe('assignees column', () => {
    describe('when the item has several assignees', () => {
      beforeEach(() => {
        createComponent({
          columnKey: COLUMN_ASSIGNEES,
          item: buildWorkItemNode(1, { widgets: [buildAssigneesWidget()] }),
        });
      });

      it('renders the assignee avatars', () => {
        expect(findAssignees().props('assignees')).toEqual(mockAssignees);
      });

      it('does not render a name', () => {
        expect(findTruncatedText().exists()).toBe(false);
      });
    });

    describe('when the item has a single assignee', () => {
      beforeEach(() => {
        createComponent({
          columnKey: COLUMN_ASSIGNEES,
          item: buildWorkItemNode(1, { widgets: [buildAssigneesWidget([mockAssignees[0]])] }),
        });
      });

      it('renders the avatar and the assignee name', () => {
        expect(findAssignees().props('assignees')).toEqual([mockAssignees[0]]);
        expect(findTruncatedText().props('text')).toBe(mockAssignees[0].name);
      });
    });
  });

  describe('labels column', () => {
    describe('when the item has labels', () => {
      beforeEach(() => {
        createComponent({
          columnKey: COLUMN_LABELS,
          item: buildWorkItemNode(1, { widgets: [buildLabelsWidget()] }),
        });
      });

      it('renders a label per label on the item', () => {
        expect(findLabels()).toHaveLength(mockLabels.length);
        expect(findLabels().at(0).props()).toMatchObject({
          title: mockLabels[0].title,
          backgroundColor: mockLabels[0].color,
          scoped: false,
        });
      });
    });

    describe('when the namespace allows scoped labels', () => {
      beforeEach(() => {
        const scopedLabel = { ...mockLabels[0], title: 'team::frontend' };
        createComponent({
          columnKey: COLUMN_LABELS,
          item: buildWorkItemNode(1, {
            widgets: [{ ...buildLabelsWidget([scopedLabel]), allowsScopedLabels: true }],
          }),
        });
      });

      it('renders a scoped label as scoped', () => {
        expect(findLabels().at(0).props('scoped')).toBe(true);
      });
    });
  });

  describe('weight column', () => {
    describe('when the item has a weight', () => {
      beforeEach(() => {
        createComponent({
          columnKey: COLUMN_WEIGHT,
          item: buildWorkItemNode(1, { widgets: [buildWeightWidget(5)] }),
        });
      });

      it('renders the weight', () => {
        expect(findWeight().text()).toBe('5');
      });
    });

    describe('when the weight is zero', () => {
      beforeEach(() => {
        createComponent({
          columnKey: COLUMN_WEIGHT,
          item: buildWorkItemNode(1, { widgets: [buildWeightWidget(0)] }),
        });
      });

      it('renders the weight rather than an empty cell', () => {
        expect(findWeight().text()).toBe('0');
      });
    });
  });

  describe('milestone column', () => {
    describe('when the item has a milestone', () => {
      beforeEach(() => {
        createComponent({
          columnKey: COLUMN_MILESTONE,
          item: buildWorkItemNode(1, { widgets: [buildMilestoneWidget()] }),
        });
      });

      it('renders the milestone', () => {
        expect(findMilestone().props('milestone')).toEqual(mockMilestone);
      });
    });
  });

  describe('iteration column', () => {
    describe('when the item has an iteration', () => {
      beforeEach(() => {
        createComponent({
          columnKey: COLUMN_ITERATION,
          item: buildWorkItemNode(1, { widgets: [buildIterationWidget()] }),
        });
      });

      it('renders the iteration', () => {
        expect(findIteration().props('iteration')).toEqual(mockIteration);
      });
    });
  });

  describe('date columns', () => {
    describe('when the item has dates', () => {
      const dateItem = buildWorkItemNode(1, {
        createdAt: '2026-01-01T00:00:00Z',
        widgets: [buildStartAndDueDateWidget({ startDate: '2026-01-01', dueDate: '2026-03-01' })],
      });

      it.each`
        columnKey            | testId               | date
        ${COLUMN_START_DATE} | ${'cell-start-date'} | ${'2026-01-01'}
        ${COLUMN_DUE_DATE}   | ${'cell-due-date'}   | ${'2026-03-01'}
        ${COLUMN_CREATED_AT} | ${'cell-created-at'} | ${'2026-01-01T00:00:00Z'}
      `('renders the $testId as a formatted date', ({ columnKey, testId, date }) => {
        createComponent({ columnKey, item: dateItem });

        const cell = wrapper.findByTestId(testId);
        expect(cell.attributes('datetime')).toBe(date);
        expect(cell.text()).toMatch(/2026/);
      });
    });
  });

  describe('health status column', () => {
    describe('when the item has a health status', () => {
      beforeEach(() => {
        createComponent({
          columnKey: COLUMN_HEALTH_STATUS,
          item: buildWorkItemNode(1, { widgets: [buildHealthStatusWidget('atRisk')] }),
        });
      });

      it('renders the health status', () => {
        expect(findHealthStatus().props('healthStatus')).toBe('atRisk');
      });
    });
  });

  describe('when the item has no value for the column', () => {
    it.each`
      columnKey               | find
      ${COLUMN_STATUS}        | ${findStatusBadge}
      ${COLUMN_ASSIGNEES}     | ${findAssignees}
      ${COLUMN_LABELS}        | ${findLabel}
      ${COLUMN_WEIGHT}        | ${findWeight}
      ${COLUMN_MILESTONE}     | ${findMilestone}
      ${COLUMN_ITERATION}     | ${findIteration}
      ${COLUMN_START_DATE}    | ${findStartDate}
      ${COLUMN_DUE_DATE}      | ${findDueDate}
      ${COLUMN_HEALTH_STATUS} | ${findHealthStatus}
    `('renders nothing for $columnKey', ({ columnKey, find }) => {
      createComponent({ columnKey });

      expect(find().exists()).toBe(false);
    });
  });

  describe('when given the title column, which the row renders itself', () => {
    beforeEach(() => {
      createComponent({ columnKey: COLUMN_TITLE });
    });

    it('renders nothing', () => {
      expect(wrapper.find('*').exists()).toBe(false);
    });
  });
});
