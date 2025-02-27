/* eslint-disable @gitlab/require-i18n-strings */
import { uniqueId } from 'lodash';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import { slugify } from '~/lib/utils/text_utility';
import { LIST_ITEM_TYPE_PROJECT, LIST_ITEM_TYPE_GROUP } from './constants';

const makeGroup = ({ name, fullName, children = [] }) => {
  const fullPath = slugify(fullName);

  return {
    type: LIST_ITEM_TYPE_GROUP,
    markedForDeletionOn: null,
    isAdjournedDeletionEnabled: true,
    permanentDeletionDate: '2025-02-26',
    fullPath,
    descriptionHtml:
      '<p data-sourcepos="1:1-1:64" dir="auto">Sapiente excepturi est eos corrupti possimus praesentium quidem.</p>',
    avatarUrl: null,
    descendantGroupsCount: 0,
    projectsCount: 1,
    groupMembersCount: 5,
    visibility: 'public',
    createdAt: '2024-09-05T11:04:39Z',
    updatedAt: '2024-10-03T18:09:02Z',
    isLinkedToSubscription: true,
    id: parseInt(uniqueId(), 10),
    avatarLabel: name,
    fullName,
    webUrl: `https://gdk.test:3443/${fullPath}`,
    parent: null,
    accessLevel: { integerValue: 50 },
    editPath: `/${fullPath}/edit`,
    availableActions: [ACTION_EDIT, ACTION_DELETE],
    actionLoadingStates: { [ACTION_DELETE]: false },
    children,
  };
};

const makeProject = ({ name, nameWithNamespace }) => {
  const fullPath = slugify(nameWithNamespace);

  return {
    type: LIST_ITEM_TYPE_PROJECT,
    markedForDeletionOn: null,
    isAdjournedDeletionEnabled: true,
    permanentDeletionDate: '2025-02-26',
    fullPath,
    archived: false,
    webUrl: `https://gdk.test:3443/${fullPath}`,
    topics: [],
    forksCount: 1,
    avatarUrl: null,
    starCount: 1,
    visibility: 'public',
    openMergeRequestsCount: 4,
    openIssuesCount: 47,
    descriptionHtml:
      '<p data-sourcepos="1:1-1:503" dir="auto">Qui nostrum occaecati eum quo dicta quam. Qui nostrum occaecati eum quo dicta quam. Qui nostrum occaecati eum quo dicta quam. Qui nostrum occaecati eum quo dicta quam. Qui nostrum occaecati eum quo dicta quam. Qui nostrum occaecati eum quo dicta quam. Qui nostrum occaecati eum quo dicta quam. Qui nostrum occaecati eum quo dicta quam. Qui nostrum occaecati eum quo dicta quam. Qui nostrum occaecati eum quo dicta quam. Qui nostrum occaecati eum quo dicta quam. Qui nostrum occaecati eum quo dicta quam.</p>',
    createdAt: '2024-09-05T11:04:37Z',
    updatedAt: '2024-12-12T18:33:54Z',
    lastActivityAt: '2024-12-12T18:33:54Z',
    userPermissions: {
      removeProject: true,
      viewEditPage: true,
    },
    isCatalogResource: false,
    exploreCatalogPath: null,
    pipeline: {
      detailedStatus: {
        id: 'failed-566-566',
        icon: 'status_failed',
        text: 'Failed',
        detailsPath: `/${fullPath}/-/pipelines/566`,
      },
    },
    id: parseInt(uniqueId(), 10),
    name,
    nameWithNamespace,
    avatarLabel: name,
    mergeRequestsAccessLevel: 'ENABLED',
    issuesAccessLevel: 'ENABLED',
    forkingAccessLevel: 'ENABLED',
    isForked: false,
    accessLevel: { integerValue: 50 },
    availableActions: [ACTION_EDIT, ACTION_DELETE],
    editPath: `/${fullPath}/edit`,
  };
};

export const projectA = makeProject({
  name: 'Project A',
  nameWithNamespace: 'Subgroup A / Nested subgroup / Project A',
});

export const projectB = makeProject({
  name: 'Project B',
  nameWithNamespace: 'Subgroup A / Project B',
});

export const nestedSubgroup = makeGroup({
  name: 'Nested subgroup',
  fullName: 'Subgroup A / Nested subgroup',
  children: [projectA],
});

export const subgroupA = makeGroup({
  name: 'Subgroup A',
  fullName: 'Subgroup A',
  children: [nestedSubgroup, projectB],
});

export const subgroupB = makeGroup({
  name: 'Subgroup B',
  fullName: 'Subgroup B',
});

export const items = [subgroupA, subgroupB];
