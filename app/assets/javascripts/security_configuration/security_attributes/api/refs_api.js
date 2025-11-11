import axios from '~/lib/utils/axios_utils';
import { buildApiUrl } from '~/api/api_utils';

const BRANCHES_PATH = '/api/:version/projects/:id/repository/branches';
const TAGS_PATH = '/api/:version/projects/:id/repository/tags';

/**
 * Generate a unique ID for a ref
 *
 * We have two ways of fetching refs: REST API and GraphQL.
 * They both handle ids differently, so this helper function is used to
 * uniquely identify a ref by combining the type and name.
 *
 * @param {String} refType - Type of ref ('branch' or 'tag')
 * @param {String} name - Name of the ref
 * @returns {String} Unique ID for the ref
 */
export const createRefId = (refType, name) => `${refType.toLowerCase()}-${name}`;

/**
 * Transform a ref object from REST API to SelectableRef format to be close to the
 * GraphQL format that will be introduced in the future. This will make it easier to
 * migrate to the GraphQL-fetch once it is available.
 *
 * @param {Object} ref - Ref object from REST API (branch or tag)
 * @param {String} refType - Type of ref ('BRANCH' or 'TAG')
 * @returns {Object} Transformed ref object
 */
const transformRefToSelectableRef = (refType) => (ref) => {
  const { name, protected: isProtected, commit } = ref;

  return {
    id: createRefId(refType, name),
    name,
    refType,
    isProtected,
    commit: {
      sha: commit.id,
      shortId: commit.short_id,
      title: commit.title,
      authoredDate: commit.committed_date || commit.authored_date,
      webPath: commit.web_url,
    },
  };
};

/**
 * Sort refs by commit date (most recent first)
 *
 * @param {Array} refs - Array of ref objects
 * @returns {Array} Sorted array of refs
 */
const sortRefsByMostRecent = (refs) => {
  return [...refs].sort((a, b) => {
    const dateA = new Date(a.commit.authoredDate);
    const dateB = new Date(b.commit.authoredDate);
    return dateB - dateA;
  });
};

/**
 * Fetch both branches and tags, transform and combine
 *
 * @param {String} projectPath - The full path of the project (e.g., 'gitlab-org/gitlab')
 * @param {Object} options - Query options
 * @param {String} options.search - Search term to filter refs
 * @param {Number} options.limit - Total number of results to return (combined from both branches and tags)
 * @returns {Promise<Array>} Promise with array of transformed refs
 */
export async function fetchRefs(projectPath, { search = '', limit = 10, sortFn = null } = {}) {
  // Fetch more than needed from each source to ensure we have enough results after combining
  const perSource = Math.ceil(limit * 1.5);

  const branchesUrl = buildApiUrl(BRANCHES_PATH).replace(':id', encodeURIComponent(projectPath));
  const tagsUrl = buildApiUrl(TAGS_PATH).replace(':id', encodeURIComponent(projectPath));

  const [branchesResponse, tagsResponse] = await Promise.all([
    axios.get(branchesUrl, {
      params: {
        search,
        sort: 'updated_desc',
        per_page: perSource,
      },
    }),
    axios.get(tagsUrl, {
      params: {
        search,
        order_by: 'updated',
        sort: 'desc',
        per_page: perSource,
      },
    }),
  ]);

  const branches = branchesResponse.data || [];
  const tags = tagsResponse.data || [];

  const transformedBranches = branches.map(transformRefToSelectableRef('BRANCH'));
  const transformedTags = tags.map(transformRefToSelectableRef('TAG'));

  const combinedRefs = [...transformedBranches, ...transformedTags];

  const sortedRefs = sortFn ? sortFn(combinedRefs) : combinedRefs;

  return sortedRefs.slice(0, limit);
}

/**
 * Fetch both branches and tags, transform, combine and sort by most recent commit date
 *
 * @param {String} projectPath - The full path of the project (e.g., 'gitlab-org/gitlab')
 * @param {Object} options - Query options
 * @param {String} options.search - Search term to filter refs
 * @param {Number} options.limit - Total number of results to return (combined from both branches and tags)
 * @returns {Promise<Array>} Promise with array of transformed and sorted refs
 */
export async function fetchMostRecentlyUpdated(projectPath, options = {}) {
  return fetchRefs(projectPath, { ...options, sortFn: sortRefsByMostRecent });
}
