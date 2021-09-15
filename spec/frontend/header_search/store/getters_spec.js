import * as getters from '~/header_search/store/getters';
import initState from '~/header_search/store/state';
import {
  MOCK_USERNAME,
  MOCK_SEARCH_PATH,
  MOCK_ISSUE_PATH,
  MOCK_MR_PATH,
  MOCK_SEARCH_CONTEXT,
  MOCK_DEFAULT_SEARCH_OPTIONS,
  MOCK_SCOPED_SEARCH_OPTIONS,
  MOCK_PROJECT,
  MOCK_GROUP,
  MOCK_ALL_PATH,
  MOCK_SEARCH,
} from '../mock_data';

describe('Header Search Store Getters', () => {
  let state;

  const createState = (initialState) => {
    state = initState({
      searchPath: MOCK_SEARCH_PATH,
      issuesPath: MOCK_ISSUE_PATH,
      mrPath: MOCK_MR_PATH,
      searchContext: MOCK_SEARCH_CONTEXT,
      ...initialState,
    });
  };

  afterEach(() => {
    state = null;
  });

  describe.each`
    group         | project         | expectedPath
    ${null}       | ${null}         | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&project_id=undefined&group_id=undefined&scope=issues`}
    ${MOCK_GROUP} | ${null}         | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&project_id=undefined&group_id=${MOCK_GROUP.id}&scope=issues`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&project_id=${MOCK_PROJECT.id}&group_id=${MOCK_GROUP.id}&scope=issues`}
  `('searchQuery', ({ group, project, expectedPath }) => {
    describe(`when group is ${group?.name} and project is ${project?.name}`, () => {
      beforeEach(() => {
        createState({
          searchContext: {
            group,
            project,
            scope: 'issues',
          },
        });
        state.search = MOCK_SEARCH;
      });

      it(`should return ${expectedPath}`, () => {
        expect(getters.searchQuery(state)).toBe(expectedPath);
      });
    });
  });

  describe.each`
    group                     | group_metadata                   | project                     | project_metadata                   | expectedPath
    ${null}                   | ${null}                          | ${null}                     | ${null}                            | ${MOCK_ISSUE_PATH}
    ${{ name: 'Test Group' }} | ${{ issues_path: 'group/path' }} | ${null}                     | ${null}                            | ${'group/path'}
    ${{ name: 'Test Group' }} | ${{ issues_path: 'group/path' }} | ${{ name: 'Test Project' }} | ${{ issues_path: 'project/path' }} | ${'project/path'}
  `('scopedIssuesPath', ({ group, group_metadata, project, project_metadata, expectedPath }) => {
    describe(`when group is ${group?.name} and project is ${project?.name}`, () => {
      beforeEach(() => {
        createState({
          searchContext: {
            group,
            group_metadata,
            project,
            project_metadata,
          },
        });
      });

      it(`should return ${expectedPath}`, () => {
        expect(getters.scopedIssuesPath(state)).toBe(expectedPath);
      });
    });
  });

  describe.each`
    group                     | group_metadata               | project                     | project_metadata               | expectedPath
    ${null}                   | ${null}                      | ${null}                     | ${null}                        | ${MOCK_MR_PATH}
    ${{ name: 'Test Group' }} | ${{ mr_path: 'group/path' }} | ${null}                     | ${null}                        | ${'group/path'}
    ${{ name: 'Test Group' }} | ${{ mr_path: 'group/path' }} | ${{ name: 'Test Project' }} | ${{ mr_path: 'project/path' }} | ${'project/path'}
  `('scopedMRPath', ({ group, group_metadata, project, project_metadata, expectedPath }) => {
    describe(`when group is ${group?.name} and project is ${project?.name}`, () => {
      beforeEach(() => {
        createState({
          searchContext: {
            group,
            group_metadata,
            project,
            project_metadata,
          },
        });
      });

      it(`should return ${expectedPath}`, () => {
        expect(getters.scopedMRPath(state)).toBe(expectedPath);
      });
    });
  });

  describe.each`
    group         | project         | expectedPath
    ${null}       | ${null}         | ${null}
    ${MOCK_GROUP} | ${null}         | ${null}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&project_id=${MOCK_PROJECT.id}&group_id=${MOCK_GROUP.id}&scope=issues`}
  `('projectUrl', ({ group, project, expectedPath }) => {
    describe(`when group is ${group?.name} and project is ${project?.name}`, () => {
      beforeEach(() => {
        createState({
          searchContext: {
            group,
            project,
            scope: 'issues',
          },
        });
        state.search = MOCK_SEARCH;
      });

      it(`should return ${expectedPath}`, () => {
        expect(getters.projectUrl(state)).toBe(expectedPath);
      });
    });
  });

  describe.each`
    group         | project         | expectedPath
    ${null}       | ${null}         | ${null}
    ${MOCK_GROUP} | ${null}         | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&group_id=${MOCK_GROUP.id}&scope=issues`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&group_id=${MOCK_GROUP.id}&scope=issues`}
  `('groupUrl', ({ group, project, expectedPath }) => {
    describe(`when group is ${group?.name} and project is ${project?.name}`, () => {
      beforeEach(() => {
        createState({
          searchContext: {
            group,
            project,
            scope: 'issues',
          },
        });
        state.search = MOCK_SEARCH;
      });

      it(`should return ${expectedPath}`, () => {
        expect(getters.groupUrl(state)).toBe(expectedPath);
      });
    });
  });

  describe('allUrl', () => {
    const expectedPath = `${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&scope=issues`;

    beforeEach(() => {
      createState({
        searchContext: {
          scope: 'issues',
        },
      });
      state.search = MOCK_SEARCH;
    });

    it(`should return ${expectedPath}`, () => {
      expect(getters.allUrl(state)).toBe(expectedPath);
    });
  });

  describe('defaultSearchOptions', () => {
    const mockGetters = {
      scopedIssuesPath: MOCK_ISSUE_PATH,
      scopedMRPath: MOCK_MR_PATH,
    };

    beforeEach(() => {
      createState();
      window.gon.current_username = MOCK_USERNAME;
    });

    it('returns the correct array', () => {
      expect(getters.defaultSearchOptions(state, mockGetters)).toStrictEqual(
        MOCK_DEFAULT_SEARCH_OPTIONS,
      );
    });
  });

  describe('scopedSearchOptions', () => {
    const mockGetters = {
      projectUrl: MOCK_PROJECT.path,
      groupUrl: MOCK_GROUP.path,
      allUrl: MOCK_ALL_PATH,
    };

    beforeEach(() => {
      createState({
        searchContext: {
          project: MOCK_PROJECT,
          group: MOCK_GROUP,
        },
      });
    });

    it('returns the correct array', () => {
      expect(getters.scopedSearchOptions(state, mockGetters)).toStrictEqual(
        MOCK_SCOPED_SEARCH_OPTIONS,
      );
    });
  });
});
