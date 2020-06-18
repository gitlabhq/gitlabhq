/*
  It is important that the simple base include parallel jobs
  as well as non-parallel jobs with spaces in the name to prevent
  us relying on spaces as an indicator.
*/
export const mockBaseData = {
  stages: [
    {
      name: 'test',
      groups: [
        {
          name: 'jest',
          size: 2,
          jobs: [{ name: 'jest 1/2', needs: ['frontend fixtures'] }, { name: 'jest 2/2' }],
        },
        {
          name: 'rspec',
          size: 1,
          jobs: [{ name: 'rspec', needs: ['frontend fixtures'] }],
        },
      ],
    },
    {
      name: 'fixtures',
      groups: [
        {
          name: 'frontend fixtures',
          size: 1,
          jobs: [{ name: 'frontend fixtures' }],
        },
      ],
    },
    {
      name: 'un-needed',
      groups: [
        {
          name: 'un-needed',
          size: 1,
          jobs: [{ name: 'un-needed' }],
        },
      ],
    },
  ],
};

export const tooSmallGraph = {
  stages: [
    {
      name: 'test',
      groups: [
        {
          name: 'jest',
          size: 2,
          jobs: [{ name: 'jest 1/2' }, { name: 'jest 2/2' }],
        },
        {
          name: 'rspec',
          size: 1,
          jobs: [{ name: 'rspec', needs: ['frontend fixtures'] }],
        },
      ],
    },
    {
      name: 'fixtures',
      groups: [
        {
          name: 'frontend fixtures',
          size: 1,
          jobs: [{ name: 'frontend fixtures' }],
        },
      ],
    },
    {
      name: 'un-needed',
      groups: [
        {
          name: 'un-needed',
          size: 1,
          jobs: [{ name: 'un-needed' }],
        },
      ],
    },
  ],
};

export const unparseableGraph = [
  {
    name: 'test',
    groups: [
      {
        name: 'jest',
        size: 2,
        jobs: [{ name: 'jest 1/2', needs: ['frontend fixtures'] }, { name: 'jest 2/2' }],
      },
      {
        name: 'rspec',
        size: 1,
        jobs: [{ name: 'rspec', needs: ['frontend fixtures'] }],
      },
    ],
  },
  {
    name: 'un-needed',
    groups: [
      {
        name: 'un-needed',
        size: 1,
        jobs: [{ name: 'un-needed' }],
      },
    ],
  },
];

/*
  This represents data that has been parsed by the wrapper
*/
export const parsedData = {
  nodes: [
    {
      name: 'build_a',
      size: 1,
      jobs: [
        {
          name: 'build_a',
        },
      ],
      category: 'build',
    },
    {
      name: 'build_b',
      size: 1,
      jobs: [
        {
          name: 'build_b',
        },
      ],
      category: 'build',
    },
    {
      name: 'test_a',
      size: 1,
      jobs: [
        {
          name: 'test_a',
          needs: ['build_a'],
        },
      ],
      category: 'test',
    },
    {
      name: 'test_b',
      size: 1,
      jobs: [
        {
          name: 'test_b',
        },
      ],
      category: 'test',
    },
    {
      name: 'test_c',
      size: 1,
      jobs: [
        {
          name: 'test_c',
        },
      ],
      category: 'test',
    },
    {
      name: 'test_d',
      size: 1,
      jobs: [
        {
          name: 'test_d',
        },
      ],
      category: 'test',
    },
    {
      name: 'post_test_a',
      size: 1,
      jobs: [
        {
          name: 'post_test_a',
        },
      ],
      category: 'post-test',
    },
    {
      name: 'post_test_b',
      size: 1,
      jobs: [
        {
          name: 'post_test_b',
        },
      ],
      category: 'post-test',
    },
    {
      name: 'post_test_c',
      size: 1,
      jobs: [
        {
          name: 'post_test_c',
          needs: ['test_a', 'test_b'],
        },
      ],
      category: 'post-test',
    },
    {
      name: 'staging_a',
      size: 1,
      jobs: [
        {
          name: 'staging_a',
          needs: ['post_test_a'],
        },
      ],
      category: 'staging',
    },
    {
      name: 'staging_b',
      size: 1,
      jobs: [
        {
          name: 'staging_b',
          needs: ['post_test_b'],
        },
      ],
      category: 'staging',
    },
    {
      name: 'staging_c',
      size: 1,
      jobs: [
        {
          name: 'staging_c',
        },
      ],
      category: 'staging',
    },
    {
      name: 'staging_d',
      size: 1,
      jobs: [
        {
          name: 'staging_d',
        },
      ],
      category: 'staging',
    },
    {
      name: 'staging_e',
      size: 1,
      jobs: [
        {
          name: 'staging_e',
        },
      ],
      category: 'staging',
    },
    {
      name: 'canary_a',
      size: 1,
      jobs: [
        {
          name: 'canary_a',
          needs: ['staging_a', 'staging_b'],
        },
      ],
      category: 'canary',
    },
    {
      name: 'canary_b',
      size: 1,
      jobs: [
        {
          name: 'canary_b',
        },
      ],
      category: 'canary',
    },
    {
      name: 'canary_c',
      size: 1,
      jobs: [
        {
          name: 'canary_c',
          needs: ['staging_b'],
        },
      ],
      category: 'canary',
    },
    {
      name: 'production_a',
      size: 1,
      jobs: [
        {
          name: 'production_a',
          needs: ['canary_a'],
        },
      ],
      category: 'production',
    },
    {
      name: 'production_b',
      size: 1,
      jobs: [
        {
          name: 'production_b',
        },
      ],
      category: 'production',
    },
    {
      name: 'production_c',
      size: 1,
      jobs: [
        {
          name: 'production_c',
        },
      ],
      category: 'production',
    },
    {
      name: 'production_d',
      size: 1,
      jobs: [
        {
          name: 'production_d',
          needs: ['canary_c'],
        },
      ],
      category: 'production',
    },
  ],
  links: [
    {
      source: 'build_a',
      target: 'test_a',
      value: 10,
    },
    {
      source: 'test_a',
      target: 'post_test_c',
      value: 10,
    },
    {
      source: 'test_b',
      target: 'post_test_c',
      value: 10,
    },
    {
      source: 'post_test_a',
      target: 'staging_a',
      value: 10,
    },
    {
      source: 'post_test_b',
      target: 'staging_b',
      value: 10,
    },
    {
      source: 'staging_a',
      target: 'canary_a',
      value: 10,
    },
    {
      source: 'staging_b',
      target: 'canary_a',
      value: 10,
    },
    {
      source: 'staging_b',
      target: 'canary_c',
      value: 10,
    },
    {
      source: 'canary_a',
      target: 'production_a',
      value: 10,
    },
    {
      source: 'canary_c',
      target: 'production_d',
      value: 10,
    },
  ],
};
