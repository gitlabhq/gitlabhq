import { formatIssueInput, filterVariables } from '~/boards/boards_util';

describe('formatIssueInput', () => {
  it('correctly merges boardConfig into the issue', () => {
    const boardConfig = {
      labels: [
        {
          type: 'GroupLabel',
          id: 44,
        },
      ],
      assigneeId: '55',
      milestoneId: 66,
      weight: 1,
    };

    const issueInput = {
      labelIds: ['gid://gitlab/GroupLabel/5'],
      projectPath: 'gitlab-org/gitlab-test',
      id: 'gid://gitlab/Issue/11',
    };

    const result = formatIssueInput(issueInput, boardConfig);
    expect(result).toEqual({
      projectPath: 'gitlab-org/gitlab-test',
      id: 'gid://gitlab/Issue/11',
      labelIds: ['gid://gitlab/GroupLabel/5', 'gid://gitlab/GroupLabel/44'],
      assigneeIds: ['gid://gitlab/User/55'],
      milestoneId: 'gid://gitlab/Milestone/66',
    });
  });
});

describe('filterVariables', () => {
  it.each([
    [
      'correctly processes array filter values',
      {
        filters: {
          'not[filterA]': ['val1', 'val2'],
        },
        expected: {
          not: {
            filterA: ['val1', 'val2'],
          },
        },
      },
    ],
    [
      "renames a filter if 'remap' method is available",
      {
        filters: {
          filterD: 'some value',
        },
        expected: {
          filterA: 'some value',
          not: {},
        },
      },
    ],
    [
      'correctly processes a negated filter that supports negation',
      {
        filters: {
          'not[filterA]': 'some value 1',
          'not[filterB]': 'some value 2',
        },
        expected: {
          not: {
            filterA: 'some value 1',
          },
        },
      },
    ],
    [
      'correctly removes an unsupported filter depending on issuableType',
      {
        issuableType: 'epic',
        filters: {
          filterA: 'some value 1',
          filterE: 'some value 2',
        },
        expected: {
          filterE: 'some value 2',
          not: {},
        },
      },
    ],
    [
      'applies a transform when the filter value needs to be modified',
      {
        filters: {
          filterC: 'abc',
          'not[filterC]': 'def',
        },
        expected: {
          filterC: 'ABC',
          not: {
            filterC: 'DEF',
          },
        },
      },
    ],
  ])('%s', (_, { filters, issuableType = 'issue', expected }) => {
    const result = filterVariables({
      filters,
      issuableType,
      filterInfo: {
        filterA: {
          negatedSupport: true,
        },
        filterB: {
          negatedSupport: false,
        },
        filterC: {
          negatedSupport: true,
          transform: (val) => val.toUpperCase(),
        },
        filterD: {
          remap: () => 'filterA',
        },
        filterE: {
          negatedSupport: true,
        },
      },
      filterFields: {
        issue: ['filterA', 'filterB', 'filterC', 'filterD'],
        epic: ['filterE'],
      },
    });

    expect(result).toEqual(expected);
  });
});
