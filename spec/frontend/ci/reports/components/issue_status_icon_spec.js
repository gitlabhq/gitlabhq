import { shallowMount } from '@vue/test-utils';
import ReportItem from '~/ci/reports/components/issue_status_icon.vue';
import { STATUS_FAILED, STATUS_NEUTRAL, STATUS_SUCCESS } from '~/ci/reports/constants';

describe('IssueStatusIcon', () => {
  let wrapper;

  const createComponent = ({ status }) => {
    wrapper = shallowMount(ReportItem, {
      propsData: {
        status,
      },
    });
  };

  it.each([STATUS_SUCCESS, STATUS_NEUTRAL, STATUS_FAILED])(
    'renders "%s" state correctly',
    (status) => {
      createComponent({ status });

      expect(wrapper.element).toMatchSnapshot();
    },
  );
});
