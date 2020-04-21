export const baseReport = {
  results: {
    'http://about.gitlab.com/users/sign_in': [
      {
        code: 'WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Fail',
        type: 'error',
        typeCode: 1,
        message:
          'This element has insufficient contrast at this conformance level. Expected a contrast ratio of at least 4.5:1, but text in this element has a contrast ratio of 2.82:1. Recommendation:  change background to #d1470c.',
        context:
          '<a class="btn btn-nav-cta btn-nav-link-cta" href="/free-trial">\nGet free trial\n</a>',
        selector: '#main-nav > div:nth-child(2) > ul > div:nth-child(8) > a',
        runner: 'htmlcs',
        runnerExtras: {},
      },
    ],
    'https://about.gitlab.com': [
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
  },
};

export const parsedBaseReport = [
  '{"code":"WCAG2AA.Principle1.Guideline1_4.1_4_3.G18.Fail","type":"error","typeCode":1,"message":"This element has insufficient contrast at this conformance level. Expected a contrast ratio of at least 4.5:1, but text in this element has a contrast ratio of 2.82:1. Recommendation:  change background to #d1470c.","context":"<a class=\\"btn btn-nav-cta btn-nav-link-cta\\" href=\\"/free-trial\\">\\nGet free trial\\n</a>","selector":"#main-nav > div:nth-child(2) > ul > div:nth-child(8) > a","runner":"htmlcs","runnerExtras":{}}',
  '{"code":"WCAG2AA.Principle4.Guideline4_1.4_1_2.H91.A.NoContent","type":"error","typeCode":1,"message":"Anchor element found with a valid href attribute, but no link content has been supplied.","context":"<a href=\\"/\\" class=\\"navbar-brand animated\\"><svg height=\\"36\\" viewBox=\\"0 0 1...</a>","selector":"#main-nav > div:nth-child(1) > a","runner":"htmlcs","runnerExtras":{}}',
];

export const headReport = {
  results: {
    'http://about.gitlab.com/users/sign_in': [
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
    'https://about.gitlab.com': [
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
  },
};

export const comparedReportResult = {
  status: 'failed',
  summary: {
    total: 2,
    notes: 0,
    errors: 2,
    warnings: 0,
  },
  new_errors: [headReport.results['http://about.gitlab.com/users/sign_in'][0]],
  new_notes: [],
  new_warnings: [],
  resolved_errors: [baseReport.results['http://about.gitlab.com/users/sign_in'][0]],
  resolved_notes: [],
  resolved_warnings: [],
  existing_errors: [headReport.results['https://about.gitlab.com'][0]],
  existing_notes: [],
  existing_warnings: [],
};
