import organizationGroupsGraphQlResponse from 'test_fixtures/graphql/organizations/groups.query.graphql.json';
import organizationProjectsGraphQlResponse from 'test_fixtures/graphql/organizations/projects.query.graphql.json';
import { formatGroups, formatProjects, timestampType } from '~/organizations/shared/utils';
import { formatGraphQLProjects } from '~/vue_shared/components/projects_list/formatter';
import { formatGraphQLGroups } from '~/vue_shared/components/groups_list/formatter';
import { SORT_CREATED_AT, SORT_UPDATED_AT, SORT_NAME } from '~/organizations/shared/constants';
import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';

jest.mock('~/vue_shared/plugins/global_toast');

const {
  data: {
    organization: {
      groups: { nodes: organizationGroups },
    },
  },
} = organizationGroupsGraphQlResponse;

const {
  data: {
    organization: {
      projects: { nodes: organizationProjects },
    },
  },
} = organizationProjectsGraphQlResponse;

describe('formatGroups', () => {
  it('returns result from formatGraphQLGroups and adds editPath', () => {
    expect(formatGroups(organizationGroups)).toEqual(
      formatGraphQLGroups(organizationGroups).map((group) => ({
        ...group,
        editPath: group.organizationEditPath,
      })),
    );
  });
});

describe('formatProjects', () => {
  it('returns result from formatGraphQLProjects and adds editPath', () => {
    expect(formatProjects(organizationProjects)).toEqual(
      formatGraphQLProjects(organizationProjects).map((project) => ({
        ...project,
        editPath: project.organizationEditPath,
      })),
    );
  });
});

describe('timestampType', () => {
  describe.each`
    sortName           | expectedTimestampType
    ${SORT_CREATED_AT} | ${TIMESTAMP_TYPE_CREATED_AT}
    ${SORT_UPDATED_AT} | ${TIMESTAMP_TYPE_UPDATED_AT}
    ${SORT_NAME}       | ${TIMESTAMP_TYPE_CREATED_AT}
  `('when sort name is $sortName', ({ sortName, expectedTimestampType }) => {
    it(`returns ${expectedTimestampType}`, () => {
      expect(timestampType(sortName)).toBe(expectedTimestampType);
    });
  });
});
