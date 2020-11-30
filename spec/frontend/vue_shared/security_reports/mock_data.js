export const mockFindings = [
  {
    id: null,
    report_type: 'dependency_scanning',
    name: 'Cross-site Scripting in serialize-javascript',
    severity: 'critical',
    scanner: {
      external_id: 'gemnasium',
      name: 'Gemnasium',
      version: '1.1.1',
      url: 'https://gitlab.com/gitlab-org/security-products/gemnasium',
    },
    identifiers: [
      {
        external_type: 'gemnasium',
        external_id: '58caa017-9a9a-46d6-bab2-ec930f46833c',
        name: 'Gemnasium-58caa017-9a9a-46d6-bab2-ec930f46833c',
        url:
          'https://deps.sec.gitlab.com/packages/npm/serialize-javascript/versions/1.7.0/advisories',
      },
      {
        external_type: 'cve',
        external_id: 'CVE-2019-16769',
        name: 'CVE-2019-16769',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-16769',
      },
    ],
    project_fingerprint: '09df9f4d11c8deb93d81bdcc39f7667b44143298',
    create_vulnerability_feedback_issue_path: '/gitlab-org/gitlab-ui/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/gitlab-ui/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path: '/gitlab-org/gitlab-ui/vulnerability_feedback',
    project: {
      id: 7071551,
      name: 'gitlab-ui',
      full_path: '/gitlab-org/gitlab-ui',
      full_name: 'GitLab.org / gitlab-ui',
    },
    dismissal_feedback: null,
    issue_feedback: null,
    merge_request_feedback: null,
    description:
      'The serialize-javascript npm package is vulnerable to Cross-site Scripting (XSS). It does not properly mitigate against unsafe characters in serialized regular expressions. If serialized data of regular expression objects are used in an environment other than Node.js, it is affected by this vulnerability.',
    links: [{ url: 'https://nvd.nist.gov/vuln/detail/CVE-2019-16769' }],
    location: {
      file: 'yarn.lock',
      dependency: { package: { name: 'serialize-javascript' }, version: '1.7.0' },
    },
    remediations: [null],
    solution: 'Upgrade to version 2.1.1 or above.',
    state: 'opened',
    blob_path: '/gitlab-org/gitlab-ui/blob/ad137f0a8ac59af961afe47d04e5cc062c6864a9/yarn.lock',
    evidence: 'Credit Card Detected: Diners Card',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name: '3rd party CORS request may execute in jquery',
    severity: 'high',
    scanner: { external_id: 'retire.js', name: 'Retire.js' },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2015-9251',
        name: 'CVE-2015-9251',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-9251',
      },
    ],
    project_fingerprint: '1ecd3b214cf39c0b9ad23a0a9679778d7cf55876',
    create_vulnerability_feedback_issue_path: '/gitlab-org/gitlab-ui/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/gitlab-ui/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path: '/gitlab-org/gitlab-ui/vulnerability_feedback',
    project: {
      id: 7071551,
      name: 'gitlab-ui',
      full_path: '/gitlab-org/gitlab-ui',
      full_name: 'GitLab.org / gitlab-ui',
    },
    dismissal_feedback: {
      id: 2528,
      created_at: '2019-08-26T12:30:32.349Z',
      project_id: 7071551,
      author: {
        id: 181229,
        name: "Lukas 'Eipi' Eipert",
        username: 'leipert',
        state: 'active',
        avatar_url:
          'https://secure.gravatar.com/avatar/19a1f1260fa70323f35bc508927921a2?s=80\u0026d=identicon',
        web_url: 'https://gitlab.com/leipert',
        status_tooltip_html: null,
        path: '/leipert',
      },
      comment_details: {
        comment: 'This particular jQuery version appears in a test path of tinycolor2.\n',
        comment_timestamp: '2019-08-26T12:30:37.610Z',
        comment_author: {
          id: 181229,
          name: "Lukas 'Eipi' Eipert",
          username: 'leipert',
          state: 'active',
          avatar_url:
            'https://secure.gravatar.com/avatar/19a1f1260fa70323f35bc508927921a2?s=80\u0026d=identicon',
          web_url: 'https://gitlab.com/leipert',
          status_tooltip_html: null,
          path: '/leipert',
        },
      },
      pipeline: { id: 78375355, path: '/gitlab-org/gitlab-ui/pipelines/78375355' },
      destroy_vulnerability_feedback_dismissal_path:
        '/gitlab-org/gitlab-ui/vulnerability_feedback/2528',
      category: 'dependency_scanning',
      feedback_type: 'dismissal',
      branch: 'leipert-dogfood-secure',
      project_fingerprint: '1ecd3b214cf39c0b9ad23a0a9679778d7cf55876',
    },
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      { url: 'https://github.com/jquery/jquery/issues/2432' },
      { url: 'http://blog.jquery.com/2016/01/08/jquery-2-2-and-1-12-released/' },
      { url: 'https://nvd.nist.gov/vuln/detail/CVE-2015-9251' },
      { url: 'http://research.insecurelabs.org/jquery/test/' },
    ],
    location: {
      file: 'node_modules/tinycolor2/demo/jquery-1.9.1.js',
      dependency: { package: { name: 'jquery' }, version: '1.9.1' },
    },
    remediations: [null],
    solution: null,
    state: 'dismissed',
    blob_path:
      '/gitlab-org/gitlab-ui/blob/ad137f0a8ac59af961afe47d04e5cc062c6864a9/node_modules/tinycolor2/demo/jquery-1.9.1.js',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name:
      'jQuery before 3.4.0, as used in Drupal, Backdrop CMS, and other products, mishandles jQuery.extend(true, {}, ...) because of Object.prototype pollution in jquery',
    severity: 'low',
    scanner: { external_id: 'retire.js', name: 'Retire.js' },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2019-11358',
        name: 'CVE-2019-11358',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-11358',
      },
    ],
    project_fingerprint: 'aeb4b2442d92d0ccf7023f0c220bda8b4ba910e3',
    create_vulnerability_feedback_issue_path: '/gitlab-org/gitlab-ui/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/gitlab-ui/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path: '/gitlab-org/gitlab-ui/vulnerability_feedback',
    project: {
      id: 7071551,
      name: 'gitlab-ui',
      full_path: '/gitlab-org/gitlab-ui',
      full_name: 'GitLab.org / gitlab-ui',
    },
    dismissal_feedback: {
      id: 4197,
      created_at: '2019-11-14T11:03:18.472Z',
      project_id: 7071551,
      author: {
        id: 181229,
        name: "Lukas 'Eipi' Eipert",
        username: 'leipert',
        state: 'active',
        avatar_url:
          'https://secure.gravatar.com/avatar/19a1f1260fa70323f35bc508927921a2?s=80\u0026d=identicon',
        web_url: 'https://gitlab.com/leipert',
        status_tooltip_html: null,
        path: '/leipert',
      },
      comment_details: {
        comment:
          'This is a false positive, as it just part of some documentation assets of sass-true.',
        comment_timestamp: '2019-11-14T11:03:18.464Z',
        comment_author: {
          id: 181229,
          name: "Lukas 'Eipi' Eipert",
          username: 'leipert',
          state: 'active',
          avatar_url:
            'https://secure.gravatar.com/avatar/19a1f1260fa70323f35bc508927921a2?s=80\u0026d=identicon',
          web_url: 'https://gitlab.com/leipert',
          status_tooltip_html: null,
          path: '/leipert',
        },
      },
      destroy_vulnerability_feedback_dismissal_path:
        '/gitlab-org/gitlab-ui/vulnerability_feedback/4197',
      category: 'dependency_scanning',
      feedback_type: 'dismissal',
      branch: null,
      project_fingerprint: 'aeb4b2442d92d0ccf7023f0c220bda8b4ba910e3',
    },
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      { url: 'https://blog.jquery.com/2019/04/10/jquery-3-4-0-released/' },
      { url: 'https://nvd.nist.gov/vuln/detail/CVE-2019-11358' },
      { url: 'https://github.com/jquery/jquery/commit/753d591aea698e57d6db58c9f722cd0808619b1b' },
    ],
    location: {
      file: 'node_modules/sass-true/docs/assets/webpack/common.min.js',
      dependency: { package: { name: 'jquery' }, version: '3.3.1' },
    },
    remediations: [null],
    solution: null,
    state: 'dismissed',
    blob_path:
      '/gitlab-org/gitlab-ui/blob/ad137f0a8ac59af961afe47d04e5cc062c6864a9/node_modules/sass-true/docs/assets/webpack/common.min.js',
  },
  {
    id: null,
    report_type: 'dependency_scanning',
    name:
      'jQuery before 3.4.0, as used in Drupal, Backdrop CMS, and other products, mishandles jQuery.extend(true, {}, ...) because of Object.prototype pollution in jquery',
    severity: 'low',
    scanner: { external_id: 'retire.js', name: 'Retire.js' },
    identifiers: [
      {
        external_type: 'cve',
        external_id: 'CVE-2019-11358',
        name: 'CVE-2019-11358',
        url: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2019-11358',
      },
    ],
    project_fingerprint: 'eb86aa13eb9d897a083ead6e134aa78aa9cadd52',
    create_vulnerability_feedback_issue_path: '/gitlab-org/gitlab-ui/vulnerability_feedback',
    create_vulnerability_feedback_merge_request_path:
      '/gitlab-org/gitlab-ui/vulnerability_feedback',
    create_vulnerability_feedback_dismissal_path: '/gitlab-org/gitlab-ui/vulnerability_feedback',
    project: {
      id: 7071551,
      name: 'gitlab-ui',
      full_path: '/gitlab-org/gitlab-ui',
      full_name: 'GitLab.org / gitlab-ui',
    },
    dismissal_feedback: {
      id: 2527,
      created_at: '2019-08-26T12:29:43.624Z',
      project_id: 7071551,
      author: {
        id: 181229,
        name: "Lukas 'Eipi' Eipert",
        username: 'leipert',
        state: 'active',
        avatar_url:
          'https://secure.gravatar.com/avatar/19a1f1260fa70323f35bc508927921a2?s=80\u0026d=identicon',
        web_url: 'https://gitlab.com/leipert',
        status_tooltip_html: null,
        path: '/leipert',
      },
      comment_details: {
        comment: 'This particular jQuery version appears in a test path of tinycolor2.',
        comment_timestamp: '2019-08-26T12:30:14.840Z',
        comment_author: {
          id: 181229,
          name: "Lukas 'Eipi' Eipert",
          username: 'leipert',
          state: 'active',
          avatar_url:
            'https://secure.gravatar.com/avatar/19a1f1260fa70323f35bc508927921a2?s=80\u0026d=identicon',
          web_url: 'https://gitlab.com/leipert',
          status_tooltip_html: null,
          path: '/leipert',
        },
      },
      pipeline: { id: 78375355, path: '/gitlab-org/gitlab-ui/pipelines/78375355' },
      destroy_vulnerability_feedback_dismissal_path:
        '/gitlab-org/gitlab-ui/vulnerability_feedback/2527',
      category: 'dependency_scanning',
      feedback_type: 'dismissal',
      branch: 'leipert-dogfood-secure',
      project_fingerprint: 'eb86aa13eb9d897a083ead6e134aa78aa9cadd52',
    },
    issue_feedback: null,
    merge_request_feedback: null,
    description: null,
    links: [
      { url: 'https://blog.jquery.com/2019/04/10/jquery-3-4-0-released/' },
      { url: 'https://nvd.nist.gov/vuln/detail/CVE-2019-11358' },
      { url: 'https://github.com/jquery/jquery/commit/753d591aea698e57d6db58c9f722cd0808619b1b' },
    ],
    location: {
      file: 'node_modules/tinycolor2/demo/jquery-1.9.1.js',
      dependency: { package: { name: 'jquery' }, version: '1.9.1' },
    },
    remediations: [null],
    solution: null,
    state: 'dismissed',
    blob_path:
      '/gitlab-org/gitlab-ui/blob/ad137f0a8ac59af961afe47d04e5cc062c6864a9/node_modules/tinycolor2/demo/jquery-1.9.1.js',
  },
];

export const sastDiffSuccessMock = {
  added: [mockFindings[0]],
  fixed: [mockFindings[1], mockFindings[2]],
  existing: [mockFindings[3]],
  base_report_created_at: '2020-01-01T10:00:00.000Z',
  base_report_out_of_date: false,
  head_report_created_at: '2020-01-10T10:00:00.000Z',
};

export const secretScanningDiffSuccessMock = {
  added: [mockFindings[0], mockFindings[1]],
  fixed: [mockFindings[2]],
  base_report_created_at: '2020-01-01T10:00:00.000Z',
  base_report_out_of_date: false,
  head_report_created_at: '2020-01-10T10:00:00.000Z',
};
