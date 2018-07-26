// eslint-disable-next-line import/prefer-default-export
export const fullReport = {
  status: 'SUCCESS',
  successText: 'SAST improved on 1 security vulnerability and degraded on 1 security vulnerability',
  errorText: 'Failed to load security report',
  hasIssues: true,
  loadingText: 'Loading security report',
  resolvedIssues: [
    {
      cve: 'CVE-2016-9999',
      file: 'Gemfile.lock',
      message: 'Test Information Leak Vulnerability in Action View',
      title: 'Test Information Leak Vulnerability in Action View',
      path: 'Gemfile.lock',
      solution:
        'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
      tool: 'bundler_audit',
      url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
      urlPath: '/Gemfile.lock',
    },
  ],
  unresolvedIssues: [
    {
      cve: 'CVE-2014-7829',
      file: 'Gemfile.lock',
      message: 'Arbitrary file existence disclosure in Action Pack',
      title: 'Arbitrary file existence disclosure in Action Pack',
      path: 'Gemfile.lock',
      solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
      tool: 'bundler_audit',
      url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
      urlPath: '/Gemfile.lock',
    },
  ],
  allIssues: [
    {
      cve: 'CVE-2016-0752',
      file: 'Gemfile.lock',
      message: 'Possible Information Leak Vulnerability in Action View',
      title: 'Possible Information Leak Vulnerability in Action View',
      path: 'Gemfile.lock',
      solution:
        'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
      tool: 'bundler_audit',
      url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
      urlPath: '/Gemfile.lock',
    },
  ],
};
