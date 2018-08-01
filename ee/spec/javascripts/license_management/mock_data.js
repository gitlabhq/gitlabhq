import { LICENSE_APPROVAL_STATUS } from 'ee/vue_shared/license_management/constants';

export const approvedLicense = {
  id: 5,
  name: 'MIT',
  approvalStatus: LICENSE_APPROVAL_STATUS.APPROVED,
};

export const blacklistedLicense = {
  id: 6,
  name: 'New BSD',
  approvalStatus: LICENSE_APPROVAL_STATUS.BLACKLISTED,
};

export const licenseBaseIssues = {
  licenses: [
    {
      count: 1,
      name: 'MIT',
    },
  ],
  dependencies: [
    {
      license: {
        name: 'MIT',
        url: 'http://opensource.org/licenses/mit-license',
      },
      dependency: {
        name: 'bundler',
        url: 'http://bundler.io',
        description: "The best way to manage your application's dependencies",
        pathes: ['.'],
      },
    },
  ],
};

export const licenseHeadIssues = {
  licenses: [
    {
      count: 3,
      name: 'New BSD',
    },
    {
      count: 1,
      name: 'MIT',
    },
  ],
  dependencies: [
    {
      license: {
        name: 'New BSD',
        url: 'http://opensource.org/licenses/BSD-3-Clause',
      },
      dependency: {
        name: 'pg',
        url: 'https://bitbucket.org/ged/ruby-pg',
        description:
          'Pg is the Ruby interface to the {PostgreSQL RDBMS}[http://www.postgresql.org/]',
        pathes: ['.'],
      },
    },
    {
      license: {
        name: 'New BSD',
        url: 'http://opensource.org/licenses/BSD-3-Clause',
      },
      dependency: {
        name: 'puma',
        url: 'http://puma.io',
        description:
          'Puma is a simple, fast, threaded, and highly concurrent HTTP 1.1 server for Ruby/Rack applications',
        pathes: ['.'],
      },
    },
    {
      license: {
        name: 'New BSD',
        url: 'http://opensource.org/licenses/BSD-3-Clause',
      },
      dependency: {
        name: 'foo',
        url: 'http://foo.io',
        description:
          'Foo is a simple, fast, threaded, and highly concurrent HTTP 1.1 server for Ruby/Rack applications',
        pathes: ['.'],
      },
    },
    {
      license: {
        name: 'MIT',
        url: 'http://opensource.org/licenses/mit-license',
      },
      dependency: {
        name: 'execjs',
        url: 'https://github.com/rails/execjs',
        description: 'Run JavaScript code from Ruby',
        pathes: ['.'],
      },
    },
  ],
};

export const licenseReport = [
  {
    name: 'New BSD',
    count: 5,
    url: 'http://opensource.org/licenses/BSD-3-Clause',
    packages: [
      {
        name: 'pg',
        url: 'https://bitbucket.org/ged/ruby-pg',
        description:
          'Pg is the Ruby interface to the {PostgreSQL RDBMS}[http://www.postgresql.org/]',
        pathes: ['.'],
      },
      {
        name: 'puma',
        url: 'http://puma.io',
        description:
          'Puma is a simple, fast, threaded, and highly concurrent HTTP 1.1 server for Ruby/Rack applications',
        pathes: ['.'],
      },
      {
        name: 'foo',
        url: 'https://bitbucket.org/ged/ruby-pg',
        description:
          'Pg is the Ruby interface to the {PostgreSQL RDBMS}[http://www.postgresql.org/]',
        pathes: ['.'],
      },
      {
        name: 'bar',
        url: 'http://puma.io',
        description:
          'Puma is a simple, fast, threaded, and highly concurrent HTTP 1.1 server for Ruby/Rack applications',
        pathes: ['.'],
      },
      {
        name: 'baz',
        url: 'https://bitbucket.org/ged/ruby-pg',
        description:
          'Pg is the Ruby interface to the {PostgreSQL RDBMS}[http://www.postgresql.org/]',
        pathes: ['.'],
      },
    ],
  },
];

export default () => {};
