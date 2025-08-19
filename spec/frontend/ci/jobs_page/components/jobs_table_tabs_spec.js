import { GlBadge, GlTab } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import JobsTableTabs from '~/ci/jobs_page/components/jobs_table_tabs.vue';
import CancelJobs from '~/ci/admin/jobs_table/components/cancel_jobs.vue';

describe('Jobs Table Tabs', () => {
  let wrapper;

  const defaultProps = {
    allJobsCount: 286,
    loading: false,
    filters: {
      kind: 'BUILD',
    },
  };

  const adminProps = {
    ...defaultProps,
    showCancelAllJobsButton: true,
  };

  const statuses = {
    success: 'SUCCESS',
    failed: 'FAILED',
    canceled: 'CANCELED',
  };

  const findAllTab = () => wrapper.findByTestId('jobs-all-tab');
  const findFinishedTab = () => wrapper.findByTestId('jobs-finished-tab');
  const findCancelJobsButton = () => wrapper.findAllComponents(CancelJobs);
  const findCountBadge = () => wrapper.findComponent(GlBadge);

  const triggerTabChange = (index) => wrapper.findAllComponents(GlTab).at(index).vm.$emit('click');

  const createComponent = (props = defaultProps) => {
    wrapper = mountExtended(JobsTableTabs, {
      provide: {
        jobStatuses: {
          ...statuses,
        },
      },
      propsData: {
        ...props,
      },
    });
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('displays All tab with count', () => {
      expect(trimText(findAllTab().text())).toBe(`All ${defaultProps.allJobsCount}`);
      expect(findCountBadge().exists()).toBe(true);
    });

    it('displays Finished tab with no count', () => {
      expect(findFinishedTab().text()).toBe('Finished');
    });

    it.each`
      tabIndex | expectedScope
      ${0}     | ${null}
      ${1}     | ${[statuses.success, statuses.failed, statuses.canceled]}
    `(
      'emits fetchJobsByStatus with $expectedScope on tab change',
      ({ tabIndex, expectedScope }) => {
        triggerTabChange(tabIndex);

        expect(wrapper.emitted()).toEqual({ fetchJobsByStatus: [[expectedScope]] });
      },
    );

    it('does not display cancel all jobs button', () => {
      expect(findCancelJobsButton().exists()).toBe(false);
    });
  });

  describe('admin mode', () => {
    it('displays cancel all jobs button', () => {
      createComponent(adminProps);

      expect(findCancelJobsButton().exists()).toBe(true);
    });
  });

  describe('with bridge filter', () => {
    beforeEach(() => {
      createComponent({ ...defaultProps, filters: { kind: 'BRIDGE' } });
    });

    it('does not display job count', () => {
      expect(trimText(findAllTab().text())).toBe('All');
      expect(findCountBadge().exists()).toBe(false);
    });
  });
});
