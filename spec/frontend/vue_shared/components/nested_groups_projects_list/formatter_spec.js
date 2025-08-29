import projectsGraphQLResponse from 'test_fixtures/graphql/organizations/projects.query.graphql.json';
import groupsGraphQlResponse from 'test_fixtures/graphql/organizations/groups.query.graphql.json';
import { formatGraphQLGroupsAndProjects } from '~/vue_shared/components/nested_groups_projects_list/formatter';
import {
  LIST_ITEM_TYPE_PROJECT,
  LIST_ITEM_TYPE_GROUP,
} from '~/vue_shared/components/nested_groups_projects_list/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import {
  ACTION_DELETE_IMMEDIATELY,
  ACTION_EDIT,
  ACTION_LEAVE,
  ACTION_RESTORE,
  ACTION_ARCHIVE,
} from '~/vue_shared/components/list_actions/constants';

const {
  data: {
    organization: {
      projects: {
        nodes: [mockProject],
      },
    },
  },
} = projectsGraphQLResponse;

const {
  data: {
    organization: {
      groups: {
        nodes: [firstMockGroup, secondMockGroup],
      },
    },
  },
} = groupsGraphQlResponse;

const mockGroupsAndProjects = [
  {
    ...firstMockGroup,
    type: LIST_ITEM_TYPE_GROUP,
    hasChildren: true,
    childrenCount: 1,
    children: [
      { ...mockProject, type: LIST_ITEM_TYPE_PROJECT },
      { ...secondMockGroup, type: LIST_ITEM_TYPE_GROUP },
    ],
  },
];

afterEach(() => {
  window.gon = {};
});

describe('formatGraphQLGroupsAndProjects', () => {
  it('correctly formats the groups and projects', () => {
    window.gon = { relative_url_root: '/gitlab' };
    const [firstItem] = formatGraphQLGroupsAndProjects(
      mockGroupsAndProjects,
      (group) => ({
        customProperty: group.fullName,
      }),
      (project) => ({
        customProperty: project.nameWithNamespace,
      }),
    );
    const [firstChild, secondChild] = firstItem.children;

    expect(firstItem).toMatchObject({
      id: getIdFromGraphQLId(firstMockGroup.id),
      avatarLabel: firstMockGroup.fullName,
      fullName: firstMockGroup.fullName,
      parent: null,
      accessLevel: {
        integerValue: 50,
      },
      availableActions: [
        ACTION_EDIT,
        ACTION_ARCHIVE,
        ACTION_RESTORE,
        ACTION_LEAVE,
        ACTION_DELETE_IMMEDIATELY,
      ],
      childrenLoading: false,
      hasChildren: true,
      relativeWebUrl: `/gitlab/${firstMockGroup.fullPath}`,
      customProperty: firstMockGroup.fullName,
    });

    expect(firstChild).toMatchObject({
      id: getIdFromGraphQLId(mockProject.id),
      nameWithNamespace: mockProject.nameWithNamespace,
      avatarLabel: mockProject.nameWithNamespace,
      mergeRequestsAccessLevel: mockProject.mergeRequestsAccessLevel.stringValue,
      issuesAccessLevel: mockProject.issuesAccessLevel.stringValue,
      forkingAccessLevel: mockProject.forkingAccessLevel.stringValue,
      accessLevel: {
        integerValue: 50,
      },
      availableActions: [ACTION_EDIT, ACTION_ARCHIVE],
      customProperty: mockProject.nameWithNamespace,
      isPersonal: false,
      relativeWebUrl: `/gitlab/${mockProject.fullPath}`,
    });

    expect(secondChild).toMatchObject({
      id: getIdFromGraphQLId(secondMockGroup.id),
      avatarLabel: secondMockGroup.fullName,
      fullName: secondMockGroup.fullName,
      parent: null,
      accessLevel: {
        integerValue: 0,
      },
      availableActions: [],
      childrenLoading: false,
      hasChildren: false,
      relativeWebUrl: `/gitlab/${secondMockGroup.fullPath}`,
      customProperty: secondMockGroup.fullName,
    });
  });
});
