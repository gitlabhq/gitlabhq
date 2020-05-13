export const mockReport = {
  status: 'failed',
  summary: {
    total: 2,
    resolved: 0,
    errored: 2,
  },
  new_errors: [
    {
      code: 'WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Fail',
      type: 'error',
      typeCode: 1,
      message:
        'This element has insufficient contrast at this conformance level. Expected a contrast ratio of at least 4.5:1, but text in this element has a contrast ratio of 3.84:1. Recommendation:  change text colour to #767676.',
      context: '<a href="/stages-devops-lifecycle/" class="main-nav-link">Product</a>',
      selector: '#main-nav > div:nth-child(2) > ul > li:nth-child(1) > a',
      runner: 'htmlcs',
      runnerExtras: {},
    },
  ],
  new_notes: [],
  new_warnings: [],
  resolved_errors: [
    {
      code: 'WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent',
      type: 'error',
      typeCode: 1,
      message:
        'Anchor element found with a valid href attribute, but no link content has been supplied.',
      context: '<a href="/" class="navbar-brand animated"><svg height="36" viewBox="0 0 1...</a>',
      selector: '#main-nav > div:nth-child(1) > a',
      runner: 'htmlcs',
      runnerExtras: {},
    },
  ],
  resolved_notes: [],
  resolved_warnings: [],
  existing_errors: [
    {
      code: 'WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent',
      type: 'error',
      typeCode: 1,
      message:
        'Anchor element found with a valid href attribute, but no link content has been supplied.',
      context: '<a href="/" class="navbar-brand animated"><svg height="36" viewBox="0 0 1...</a>',
      selector: '#main-nav > div:nth-child(1) > a',
      runner: 'htmlcs',
      runnerExtras: {},
    },
  ],
  existing_notes: [],
  existing_warnings: [],
};

export default () => {};
