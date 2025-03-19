/* eslint-disable @gitlab/require-i18n-strings */
import { uniqueId } from 'lodash';
import { ACTION_EDIT, ACTION_DELETE } from '~/vue_shared/components/list_actions/constants';
import { slugify } from '~/lib/utils/text_utility';
import { LIST_ITEM_TYPE_PROJECT, LIST_ITEM_TYPE_GROUP } from './constants';

const makeGroup = ({ name, fullName, childrenToLoad = [] }) => {
  const fullPath = slugify(fullName);
  const id = parseInt(uniqueId(), 10);

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
    id,
    avatarLabel: name,
    fullName,
    webUrl: `https://gdk.test:3443/${fullPath}`,
    accessLevel: { integerValue: 50 },
    editPath: `/${fullPath}/edit`,
    availableActions: [ACTION_EDIT, ACTION_DELETE],
    children: [],
    childrenToLoad: childrenToLoad.map((child) => ({ ...child, parent: { id } })),
    hasChildren: childrenToLoad.length,
    childrenLoading: false,
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
  nameWithNamespace: 'Top-level group A / Subgroup / Nested subgroup / Project A',
});

export const projectB = makeProject({
  name: 'Project B',
  nameWithNamespace: 'Top-level group A / Project B',
});

export const nestedSubgroup = makeGroup({
  name: 'Nested subgroup',
  fullName: 'Top-level group A / Subgroup / Nested subgroup',
  childrenToLoad: [projectA],
});

export const subgroup = makeGroup({
  name: 'Subgroup',
  fullName: 'Top-level group A / Subgroup',
  childrenToLoad: [nestedSubgroup],
});

export const topLevelGroupA = makeGroup({
  name: 'Top-level group A',
  fullName: 'Top-level group A',
  childrenToLoad: [subgroup, projectB],
});

export const topLevelGroupB = makeGroup({
  name: 'Top-level group B',
  fullName: 'Top-level group B',
});

export const items = [topLevelGroupA, topLevelGroupB];
