import * as getters from '~/header_search/store/getters';
import initState from '~/header_search/store/state';
import {
  MOCK_USERNAME,
  MOCK_ISSUE_PATH,
  MOCK_MR_PATH,
  MOCK_SEARCH_CONTEXT,
  MOCK_DEFAULT_SEARCH_OPTIONS,
} from '../mock_data';

describe('Header Search Store Getters', () => {
  let state;

  const createState = (initialState) => {
    state = initState({
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
});
