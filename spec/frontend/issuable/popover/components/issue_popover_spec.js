import { GlIcon, GlPopover, GlSkeletonLoader } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import issueQueryResponse from 'test_fixtures/graphql/issuable/popover/queries/issue.query.graphql.json';
import issueQuery from 'ee_else_ce/issuable/popover/queries/issue.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import IssueDueDate from '~/boards/components/issue_due_date.vue';
import IssueMilestone from '~/issuable/components/issue_milestone.vue';
import StatusBadge from '~/issuable/components/status_badge.vue';
import IssuePopover from '~/issuable/popover/components/issue_popover.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';

describe('IssuePopover component', () => {
  /** @type {import('@vue/test-utils').Wrapper} */
  let wrapper;

  Vue.use(VueApollo);

  const { workItem } = issueQueryResponse.data.namespace;
  const cachedTitle = 'Cached title';

  const queryResponseHandler = jest.fn().mockResolvedValue(issueQueryResponse);

  const findGlPopover = () => wrapper.findComponent(GlPopover);
  const findWorkItemIcon = () => wrapper.findComponent(WorkItemTypeIcon);

  const mountComponent = ({ queryResponse = queryResponseHandler } = {}) => {
    wrapper = shallowMount(IssuePopover, {
      apolloProvider: createMockApollo([[issueQuery, queryResponse]]),
      propsData: {
        target: document.createElement('a'),
        namespacePath: 'foo/bar',
        iid: '1',
        cachedTitle,
      },
    });
  };

  it('does not call query by default', () => {
    mountComponent();

    expect(queryResponseHandler).not.toHaveBeenCalled();
  });

  describe('when loading', () => {
    beforeEach(() => {
      mountComponent();
      findGlPopover().vm.$emit('show');
    });

    it('calls query', () => {
      expect(queryResponseHandler).toHaveBeenCalledWith({ fullPath: 'foo/bar', iid: '1' });
    });

    it('shows skeleton-loader while apollo is loading', () => {
      expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
    });

    it('should not show any work item icon while apollo is loading', () => {
      expect(findWorkItemIcon().exists()).toBe(false);
    });
  });

  describe('when loaded', () => {
    beforeEach(async () => {
      mountComponent();
      findGlPopover().vm.$emit('show');
      await waitForPromises();
    });

    it('shows status badge', () => {
      expect(wrapper.findComponent(StatusBadge).props('state')).toBe(workItem.state);
    });

    it('shows opened time', () => {
      expect(wrapper.text()).toContain('Opened 4 days ago');
    });

    it('shows title', () => {
      expect(wrapper.find('[data-testid="popover-title"]').text()).toBe(workItem.title);
    });

    it('shows the work type icon', () => {
      expect(findWorkItemIcon().props('workItemType')).toBe(workItem.workItemType.name);
    });

    it('shows reference', () => {
      expect(wrapper.text()).toContain(workItem.fullReference);
    });

    it('shows confidential icon', () => {
      expect(wrapper.findComponent(GlIcon).props('name')).toBe('eye-slash');
    });

    it('shows due date', () => {
      expect(wrapper.findComponent(IssueDueDate).props()).toMatchObject({
        startDate: '2020-07-03',
        date: '2020-07-05',
        closed: false,
      });
    });

    it('shows milestone', () => {
      expect(wrapper.findComponent(IssueMilestone).props('milestone')).toMatchObject({
        title: '15.2',
        startDate: '2020-07-01',
        dueDate: '2020-07-30',
      });
    });
  });

  describe('when request returns null', () => {
    const emptyResponseHandler = jest.fn().mockResolvedValue({ data: { namespace: null } });

    beforeEach(async () => {
      mountComponent({ queryResponse: emptyResponseHandler });
      findGlPopover().vm.$emit('show');
      await waitForPromises();
    });

    it('shows cached title', () => {
      expect(wrapper.find('[data-testid="popover-title"]').text()).toBe(cachedTitle);
    });

    it('does not show status badge', () => {
      expect(wrapper.findComponent(StatusBadge).exists()).toBe(false);
    });
  });
});
