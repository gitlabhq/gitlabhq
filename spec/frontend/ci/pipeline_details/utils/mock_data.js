export const missingJob = 'missing_job';

/*
  It is important that the base include parallel jobs
  as well as non-parallel jobs with spaces in the name to prevent
  us relying on spaces as an indicator.
*/

export const mockParsedGraphQLNodes = [
  {
    category: 'build',
    name: 'build_a',
    size: 1,
    jobs: [
      {
        name: 'build_a',
        needs: [],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'build',
    name: 'build_b',
    size: 1,
    jobs: [
      {
        name: 'build_b',
        needs: [],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'test',
    name: 'test_a',
    size: 1,
    jobs: [
      {
        name: 'test_a',
        needs: ['build_a'],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'test',
    name: 'test_b',
    size: 1,
    jobs: [
      {
        name: 'test_b',
        needs: [],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'test',
    name: 'test_c',
    size: 1,
    jobs: [
      {
        name: 'test_c',
        needs: [],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'test',
    name: 'test_d',
    size: 1,
    jobs: [
      {
        name: 'test_d',
        needs: [],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'post-test',
    name: 'post_test_a',
    size: 1,
    jobs: [
      {
        name: 'post_test_a',
        needs: [],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'post-test',
    name: 'post_test_b',
    size: 1,
    jobs: [
      {
        name: 'post_test_b',
        needs: [],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'post-test',
    name: 'post_test_c',
    size: 1,
    jobs: [
      {
        name: 'post_test_c',
        needs: ['test_b', 'test_a'],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'staging',
    name: 'staging_a',
    size: 1,
    jobs: [
      {
        name: 'staging_a',
        needs: ['post_test_a'],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'staging',
    name: 'staging_b',
    size: 1,
    jobs: [
      {
        name: 'staging_b',
        needs: ['post_test_b'],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'staging',
    name: 'staging_c',
    size: 1,
    jobs: [
      {
        name: 'staging_c',
        needs: [],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'staging',
    name: 'staging_d',
    size: 1,
    jobs: [
      {
        name: 'staging_d',
        needs: [],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'staging',
    name: 'staging_e',
    size: 1,
    jobs: [
      {
        name: 'staging_e',
        needs: [],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'canary',
    name: 'canary_a',
    size: 1,
    jobs: [
      {
        name: 'canary_a',
        needs: ['staging_b', 'staging_a'],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'canary',
    name: 'canary_b',
    size: 1,
    jobs: [
      {
        name: 'canary_b',
        needs: [],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'canary',
    name: 'canary_c',
    size: 1,
    jobs: [
      {
        name: 'canary_c',
        needs: ['staging_b'],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'production',
    name: 'production_a',
    size: 1,
    jobs: [
      {
        name: 'production_a',
        needs: ['canary_a'],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'production',
    name: 'production_b',
    size: 1,
    jobs: [
      {
        name: 'production_b',
        needs: [],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'production',
    name: 'production_c',
    size: 1,
    jobs: [
      {
        name: 'production_c',
        needs: [],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'production',
    name: 'production_d',
    size: 1,
    jobs: [
      {
        name: 'production_d',
        needs: ['canary_c'],
      },
    ],
    __typename: 'CiGroup',
  },
  {
    category: 'production',
    name: 'production_e',
    size: 1,
    jobs: [
      {
        name: 'production_e',
        needs: [missingJob],
      },
    ],
    __typename: 'CiGroup',
  },
];
