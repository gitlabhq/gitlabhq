import { shallowMount } from '@vue/test-utils';
import component from '~/reports/codequality_report/components/codequality_issue_body.vue';
import { STATUS_FAILED, STATUS_NEUTRAL, STATUS_SUCCESS } from '~/reports/constants';

describe('code quality issue body issue body', () => {
  let wrapper;

  const codequalityIssue = {
    name:
      'rubygem-rest-client: session fixation vulnerability via Set-Cookie headers in 30x redirection responses',
    path: 'Gemfile.lock',
    severity: 'normal',
    type: 'Issue',
    urlPath: '/Gemfile.lock#L22',
  };

  const mountWithStatus = initialStatus => {
    wrapper = shallowMount(component, {
      propsData: {
        issue: codequalityIssue,
        status: initialStatus,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with success', () => {
    it('renders fixed label', () => {
      mountWithStatus(STATUS_SUCCESS);

      expect(wrapper.text()).toContain('Fixed');
    });
  });

  describe('without success', () => {
    it('renders fixed label', () => {
      mountWithStatus(STATUS_FAILED);

      expect(wrapper.text()).not.toContain('Fixed');
    });
  });

  describe('name', () => {
    it('renders name', () => {
      mountWithStatus(STATUS_NEUTRAL);

      expect(wrapper.text()).toContain(codequalityIssue.name);
    });
  });

  describe('path', () => {
    it('renders the report-link path using the correct code quality issue', () => {
      mountWithStatus(STATUS_NEUTRAL);

      expect(wrapper.find('report-link-stub').props('issue')).toBe(codequalityIssue);
    });
  });
});
