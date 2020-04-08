import { shallowMount } from '@vue/test-utils';
import AccessibilityIssueBody from '~/reports/accessibility_report/components/accessibility_issue_body.vue';

const issue = {
  name:
    'The accessibility scanning found 2 errors of the following type: WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent',
  code: 'WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent',
  message: 'This element has insufficient contrast at this conformance level.',
  status: 'failed',
  className: 'spec.test_spec',
  learnMoreUrl: 'https://www.w3.org/TR/WCAG20-TECHS/H91.html',
};

describe('CustomMetricsForm', () => {
  let wrapper;

  const mountComponent = ({ name, code, message, status, className }, isNew = false) => {
    wrapper = shallowMount(AccessibilityIssueBody, {
      propsData: {
        issue: {
          name,
          code,
          message,
          status,
          className,
        },
        isNew,
      },
    });
  };

  const findIsNewBadge = () => wrapper.find({ ref: 'accessibility-issue-is-new-badge' });

  beforeEach(() => {
    mountComponent(issue);
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('Displays the issue message', () => {
    const description = wrapper.find({ ref: 'accessibility-issue-description' }).text();

    expect(description).toContain(`Message: ${issue.message}`);
  });

  describe('When an issue code is present', () => {
    it('Creates the correct URL for learning more about the issue code', () => {
      const learnMoreUrl = wrapper
        .find({ ref: 'accessibility-issue-learn-more' })
        .attributes('href');

      expect(learnMoreUrl).toEqual(issue.learnMoreUrl);
    });
  });

  describe('When an issue code is not present', () => {
    beforeEach(() => {
      mountComponent({
        ...issue,
        code: undefined,
      });
    });

    it('Creates a URL leading to the overview documentation page', () => {
      const learnMoreUrl = wrapper
        .find({ ref: 'accessibility-issue-learn-more' })
        .attributes('href');

      expect(learnMoreUrl).toEqual('https://www.w3.org/TR/WCAG20-TECHS/Overview.html');
    });
  });

  describe('When an issue code does not contain the TECHS code', () => {
    beforeEach(() => {
      mountComponent({
        ...issue,
        code: 'WCAG2AA.Principle4.Guideline4_1.4_1_2',
      });
    });

    it('Creates a URL leading to the overview documentation page', () => {
      const learnMoreUrl = wrapper
        .find({ ref: 'accessibility-issue-learn-more' })
        .attributes('href');

      expect(learnMoreUrl).toEqual('https://www.w3.org/TR/WCAG20-TECHS/Overview.html');
    });
  });

  describe('When issue is new', () => {
    beforeEach(() => {
      mountComponent(issue, true);
    });

    it('Renders the new badge', () => {
      expect(findIsNewBadge().exists()).toEqual(true);
    });
  });

  describe('When issue is not new', () => {
    beforeEach(() => {
      mountComponent(issue, false);
    });

    it('Does not render the new badge', () => {
      expect(findIsNewBadge().exists()).toEqual(false);
    });
  });
});
