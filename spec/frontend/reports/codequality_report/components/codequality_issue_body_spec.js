import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import component from '~/reports/codequality_report/components/codequality_issue_body.vue';
import { STATUS_FAILED, STATUS_NEUTRAL, STATUS_SUCCESS } from '~/reports/constants';

describe('code quality issue body issue body', () => {
  let wrapper;

  const findSeverityIcon = () => wrapper.findByTestId('codequality-severity-icon');
  const findGlIcon = () => wrapper.find(GlIcon);

  const codequalityIssue = {
    name:
      'rubygem-rest-client: session fixation vulnerability via Set-Cookie headers in 30x redirection responses',
    path: 'Gemfile.lock',
    severity: 'normal',
    type: 'Issue',
    urlPath: '/Gemfile.lock#L22',
  };

  const createComponent = (initialStatus, issue = codequalityIssue) => {
    wrapper = extendedWrapper(
      shallowMount(component, {
        propsData: {
          issue,
          status: initialStatus,
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('severity rating', () => {
    it.each`
      severity      | iconClass               | iconName
      ${'info'}     | ${'text-primary-400'}   | ${'severity-info'}
      ${'minor'}    | ${'text-warning-200'}   | ${'severity-low'}
      ${'major'}    | ${'text-warning-400'}   | ${'severity-medium'}
      ${'critical'} | ${'text-danger-600'}    | ${'severity-high'}
      ${'blocker'}  | ${'text-danger-800'}    | ${'severity-critical'}
      ${'unknown'}  | ${'text-secondary-400'} | ${'severity-unknown'}
      ${'invalid'}  | ${'text-secondary-400'} | ${'severity-unknown'}
    `(
      'renders correct icon for "$severity" severity rating',
      ({ severity, iconClass, iconName }) => {
        createComponent(STATUS_FAILED, {
          ...codequalityIssue,
          severity,
        });
        const icon = findGlIcon();

        expect(findSeverityIcon().classes()).toContain(iconClass);
        expect(icon.exists()).toBe(true);
        expect(icon.props('name')).toBe(iconName);
      },
    );
  });

  describe('with success', () => {
    it('renders fixed label', () => {
      createComponent(STATUS_SUCCESS);

      expect(wrapper.text()).toContain('Fixed');
    });
  });

  describe('without success', () => {
    it('does not render fixed label', () => {
      createComponent(STATUS_FAILED);

      expect(wrapper.text()).not.toContain('Fixed');
    });
  });

  describe('name', () => {
    it('renders name', () => {
      createComponent(STATUS_NEUTRAL);

      expect(wrapper.text()).toContain(codequalityIssue.name);
    });
  });

  describe('path', () => {
    it('renders the report-link path using the correct code quality issue', () => {
      createComponent(STATUS_NEUTRAL);

      expect(wrapper.find('report-link-stub').props('issue')).toBe(codequalityIssue);
    });
  });
});
