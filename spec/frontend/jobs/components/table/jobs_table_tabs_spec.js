import { GlTab } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { trimText } from 'helpers/text_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import JobsTableTabs from '~/jobs/components/table/jobs_table_tabs.vue';

describe('Jobs Table Tabs', () => {
  let wrapper;

  const defaultProps = {
    allJobsCount: 286,
    loading: false,
  };

  const statuses = {
    success: 'SUCCESS',
    failed: 'FAILED',
    canceled: 'CANCELED',
  };

  const findAllTab = () => wrapper.findByTestId('jobs-all-tab');
  const findFinishedTab = () => wrapper.findByTestId('jobs-finished-tab');

  const triggerTabChange = (index) => wrapper.findAllComponents(GlTab).at(index).vm.$emit('click');

  const createComponent = (props = defaultProps) => {
    wrapper = extendedWrapper(
      mount(JobsTableTabs, {
        provide: {
          jobStatuses: {
            ...statuses,
          },
        },
        propsData: {
          ...props,
        },
      }),
    );
  };

  beforeEach(() => {
    createComponent();
  });

  it('displays All tab with count', () => {
    expect(trimText(findAllTab().text())).toBe(`All ${defaultProps.allJobsCount}`);
  });

  it('displays Finished tab with no count', () => {
    expect(findFinishedTab().text()).toBe('Finished');
  });

  it.each`
    tabIndex | expectedScope
    ${0}     | ${null}
    ${1}     | ${[statuses.success, statuses.failed, statuses.canceled]}
  `('emits fetchJobsByStatus with $expectedScope on tab change', ({ tabIndex, expectedScope }) => {
    triggerTabChange(tabIndex);

    expect(wrapper.emitted()).toEqual({ fetchJobsByStatus: [[expectedScope]] });
  });
});
