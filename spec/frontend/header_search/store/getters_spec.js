import * as getters from '~/header_search/store/getters';
import initState from '~/header_search/store/state';
import {
  MOCK_USERNAME,
  MOCK_SEARCH_PATH,
  MOCK_ISSUE_PATH,
  MOCK_MR_PATH,
  MOCK_AUTOCOMPLETE_PATH,
  MOCK_SEARCH_CONTEXT,
  MOCK_DEFAULT_SEARCH_OPTIONS,
  MOCK_SCOPED_SEARCH_OPTIONS,
  MOCK_SCOPED_SEARCH_OPTIONS_DEF,
  MOCK_PROJECT,
  MOCK_GROUP,
  MOCK_ALL_PATH,
  MOCK_SEARCH,
  MOCK_AUTOCOMPLETE_OPTIONS,
  MOCK_GROUPED_AUTOCOMPLETE_OPTIONS,
  MOCK_SORTED_AUTOCOMPLETE_OPTIONS,
} from '../mock_data';

describe('Header Search Store Getters', () => {
  let state;

  const createState = (initialState) => {
    state = initState({
      searchPath: MOCK_SEARCH_PATH,
      issuesPath: MOCK_ISSUE_PATH,
      mrPath: MOCK_MR_PATH,
      autocompletePath: MOCK_AUTOCOMPLETE_PATH,
      searchContext: MOCK_SEARCH_CONTEXT,
      ...initialState,
    });
  };

  afterEach(() => {
    state = null;
  });

  describe.each`
    group         | project         | scope       | forSnippets | codeSearch | ref              | expectedPath
    ${null}       | ${null}         | ${null}     | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar`}
    ${null}       | ${null}         | ${null}     | ${true}     | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&snippets=true`}
    ${null}       | ${null}         | ${null}     | ${false}    | ${true}    | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&search_code=true`}
    ${null}       | ${null}         | ${null}     | ${false}    | ${false}   | ${'test-branch'} | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&repository_ref=test-branch`}
    ${MOCK_GROUP} | ${null}         | ${null}     | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&group_id=${MOCK_GROUP.id}`}
    ${null}       | ${MOCK_PROJECT} | ${null}     | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&project_id=${MOCK_PROJECT.id}`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${null}     | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&project_id=${MOCK_PROJECT.id}&group_id=${MOCK_GROUP.id}`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${'issues'} | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&project_id=${MOCK_PROJECT.id}&group_id=${MOCK_GROUP.id}&scope=issues`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${'issues'} | ${true}     | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&project_id=${MOCK_PROJECT.id}&group_id=${MOCK_GROUP.id}&scope=issues&snippets=true`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${'issues'} | ${true}     | ${true}    | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&project_id=${MOCK_PROJECT.id}&group_id=${MOCK_GROUP.id}&scope=issues&snippets=true&search_code=true`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${'issues'} | ${true}     | ${true}    | ${'test-branch'} | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&project_id=${MOCK_PROJECT.id}&group_id=${MOCK_GROUP.id}&scope=issues&snippets=true&search_code=true&repository_ref=test-branch`}
  `('searchQuery', ({ group, project, scope, forSnippets, codeSearch, ref, expectedPath }) => {
    describe(`when group is ${group?.name}, project is ${project?.name}, scope is ${scope}, for_snippets is ${forSnippets}, code_search is ${codeSearch}, and ref is ${ref}`, () => {
      beforeEach(() => {
        createState({
          searchContext: {
            group,
            project,
            scope,
            for_snippets: forSnippets,
            code_search: codeSearch,
            ref,
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
    group         | project         | scope       | forSnippets | codeSearch | ref              | expectedPath
    ${null}       | ${null}         | ${null}     | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar`}
    ${null}       | ${null}         | ${null}     | ${true}     | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&snippets=true`}
    ${null}       | ${null}         | ${null}     | ${false}    | ${true}    | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&search_code=true`}
    ${null}       | ${null}         | ${null}     | ${false}    | ${false}   | ${'test-branch'} | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&repository_ref=test-branch`}
    ${MOCK_GROUP} | ${null}         | ${null}     | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&group_id=${MOCK_GROUP.id}`}
    ${null}       | ${MOCK_PROJECT} | ${null}     | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&project_id=${MOCK_PROJECT.id}`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${null}     | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&project_id=${MOCK_PROJECT.id}&group_id=${MOCK_GROUP.id}`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${'issues'} | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&project_id=${MOCK_PROJECT.id}&group_id=${MOCK_GROUP.id}&scope=issues`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${'issues'} | ${true}     | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&project_id=${MOCK_PROJECT.id}&group_id=${MOCK_GROUP.id}&scope=issues&snippets=true`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${'issues'} | ${true}     | ${true}    | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&project_id=${MOCK_PROJECT.id}&group_id=${MOCK_GROUP.id}&scope=issues&snippets=true&search_code=true`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${'issues'} | ${true}     | ${true}    | ${'test-branch'} | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&project_id=${MOCK_PROJECT.id}&group_id=${MOCK_GROUP.id}&scope=issues&snippets=true&search_code=true&repository_ref=test-branch`}
  `('projectUrl', ({ group, project, scope, forSnippets, codeSearch, ref, expectedPath }) => {
    describe(`when group is ${group?.name}, project is ${project?.name}, scope is ${scope}, for_snippets is ${forSnippets}, code_search is ${codeSearch}, and ref is ${ref}`, () => {
      beforeEach(() => {
        createState({
          searchContext: {
            group,
            project,
            scope,
            for_snippets: forSnippets,
            code_search: codeSearch,
            ref,
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
    group         | project         | scope       | forSnippets | codeSearch | ref              | expectedPath
    ${null}       | ${null}         | ${null}     | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar`}
    ${null}       | ${null}         | ${null}     | ${true}     | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&snippets=true`}
    ${null}       | ${null}         | ${null}     | ${false}    | ${true}    | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&search_code=true`}
    ${null}       | ${null}         | ${null}     | ${false}    | ${false}   | ${'test-branch'} | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&repository_ref=test-branch`}
    ${MOCK_GROUP} | ${null}         | ${null}     | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&group_id=${MOCK_GROUP.id}`}
    ${null}       | ${MOCK_PROJECT} | ${null}     | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${null}     | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&group_id=${MOCK_GROUP.id}`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${'issues'} | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&group_id=${MOCK_GROUP.id}&scope=issues`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${'issues'} | ${true}     | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&group_id=${MOCK_GROUP.id}&scope=issues&snippets=true`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${'issues'} | ${true}     | ${true}    | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&group_id=${MOCK_GROUP.id}&scope=issues&snippets=true&search_code=true`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${'issues'} | ${true}     | ${true}    | ${'test-branch'} | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&group_id=${MOCK_GROUP.id}&scope=issues&snippets=true&search_code=true&repository_ref=test-branch`}
  `('groupUrl', ({ group, project, scope, forSnippets, codeSearch, ref, expectedPath }) => {
    describe(`when group is ${group?.name}, project is ${project?.name}, scope is ${scope}, for_snippets is ${forSnippets}, code_search is ${codeSearch}, and ref is ${ref}`, () => {
      beforeEach(() => {
        createState({
          searchContext: {
            group,
            project,
            scope,
            for_snippets: forSnippets,
            code_search: codeSearch,
            ref,
          },
        });
        state.search = MOCK_SEARCH;
      });

      it(`should return ${expectedPath}`, () => {
        expect(getters.groupUrl(state)).toBe(expectedPath);
      });
    });
  });

  describe.each`
    group         | project         | scope       | forSnippets | codeSearch | ref              | expectedPath
    ${null}       | ${null}         | ${null}     | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar`}
    ${null}       | ${null}         | ${null}     | ${true}     | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&snippets=true`}
    ${null}       | ${null}         | ${null}     | ${false}    | ${true}    | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&search_code=true`}
    ${null}       | ${null}         | ${null}     | ${false}    | ${false}   | ${'test-branch'} | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&repository_ref=test-branch`}
    ${MOCK_GROUP} | ${null}         | ${null}     | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar`}
    ${null}       | ${MOCK_PROJECT} | ${null}     | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${null}     | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${'issues'} | ${false}    | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&scope=issues`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${'issues'} | ${true}     | ${false}   | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&scope=issues&snippets=true`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${'issues'} | ${true}     | ${true}    | ${null}          | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&scope=issues&snippets=true&search_code=true`}
    ${MOCK_GROUP} | ${MOCK_PROJECT} | ${'issues'} | ${true}     | ${true}    | ${'test-branch'} | ${`${MOCK_SEARCH_PATH}?search=${MOCK_SEARCH}&nav_source=navbar&scope=issues&snippets=true&search_code=true&repository_ref=test-branch`}
  `('allUrl', ({ group, project, scope, forSnippets, codeSearch, ref, expectedPath }) => {
    describe(`when group is ${group?.name}, project is ${project?.name}, scope is ${scope}, for_snippets is ${forSnippets}, code_search is ${codeSearch}, and ref is ${ref}`, () => {
      beforeEach(() => {
        createState({
          searchContext: {
            group,
            project,
            scope,
            for_snippets: forSnippets,
            code_search: codeSearch,
            ref,
          },
        });
        state.search = MOCK_SEARCH;
      });

      it(`should return ${expectedPath}`, () => {
        expect(getters.allUrl(state)).toBe(expectedPath);
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

    it('returns the correct array if issues path is false', () => {
      mockGetters.scopedIssuesPath = undefined;
      expect(getters.defaultSearchOptions(state, mockGetters)).toStrictEqual(
        MOCK_DEFAULT_SEARCH_OPTIONS.slice(2, MOCK_DEFAULT_SEARCH_OPTIONS.length),
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
        MOCK_SCOPED_SEARCH_OPTIONS_DEF,
      );
    });
  });

  describe('autocompleteGroupedSearchOptions', () => {
    beforeEach(() => {
      createState();
      state.autocompleteOptions = MOCK_AUTOCOMPLETE_OPTIONS;
    });

    it('returns the correct grouped array', () => {
      expect(getters.autocompleteGroupedSearchOptions(state)).toStrictEqual(
        MOCK_GROUPED_AUTOCOMPLETE_OPTIONS,
      );
    });
  });

  describe.each`
    search         | defaultSearchOptions           | scopedSearchOptions           | autocompleteGroupedSearchOptions     | expectedArray
    ${null}        | ${MOCK_DEFAULT_SEARCH_OPTIONS} | ${MOCK_SCOPED_SEARCH_OPTIONS} | ${MOCK_GROUPED_AUTOCOMPLETE_OPTIONS} | ${MOCK_DEFAULT_SEARCH_OPTIONS}
    ${MOCK_SEARCH} | ${MOCK_DEFAULT_SEARCH_OPTIONS} | ${MOCK_SCOPED_SEARCH_OPTIONS} | ${[]}                                | ${MOCK_SCOPED_SEARCH_OPTIONS}
    ${MOCK_SEARCH} | ${MOCK_DEFAULT_SEARCH_OPTIONS} | ${[]}                         | ${MOCK_GROUPED_AUTOCOMPLETE_OPTIONS} | ${MOCK_SORTED_AUTOCOMPLETE_OPTIONS}
    ${MOCK_SEARCH} | ${MOCK_DEFAULT_SEARCH_OPTIONS} | ${MOCK_SCOPED_SEARCH_OPTIONS} | ${MOCK_GROUPED_AUTOCOMPLETE_OPTIONS} | ${MOCK_SCOPED_SEARCH_OPTIONS.concat(MOCK_SORTED_AUTOCOMPLETE_OPTIONS)}
    ${1}           | ${MOCK_DEFAULT_SEARCH_OPTIONS} | ${[]}                         | ${[]}                                | ${[]}
    ${'('}         | ${MOCK_DEFAULT_SEARCH_OPTIONS} | ${[]}                         | ${[]}                                | ${[]}
    ${'t'}         | ${MOCK_DEFAULT_SEARCH_OPTIONS} | ${MOCK_SCOPED_SEARCH_OPTIONS} | ${MOCK_GROUPED_AUTOCOMPLETE_OPTIONS} | ${MOCK_SORTED_AUTOCOMPLETE_OPTIONS}
    ${'te'}        | ${MOCK_DEFAULT_SEARCH_OPTIONS} | ${MOCK_SCOPED_SEARCH_OPTIONS} | ${MOCK_GROUPED_AUTOCOMPLETE_OPTIONS} | ${MOCK_SORTED_AUTOCOMPLETE_OPTIONS}
    ${'tes'}       | ${MOCK_DEFAULT_SEARCH_OPTIONS} | ${MOCK_SCOPED_SEARCH_OPTIONS} | ${MOCK_GROUPED_AUTOCOMPLETE_OPTIONS} | ${MOCK_SCOPED_SEARCH_OPTIONS.concat(MOCK_SORTED_AUTOCOMPLETE_OPTIONS)}
  `(
    'searchOptions',
    ({
      search,
      defaultSearchOptions,
      scopedSearchOptions,
      autocompleteGroupedSearchOptions,
      expectedArray,
    }) => {
      describe(`when search is ${search} and the defaultSearchOptions${
        defaultSearchOptions.length ? '' : ' do not'
      } exist, scopedSearchOptions${
        scopedSearchOptions.length ? '' : ' do not'
      } exist, and autocompleteGroupedSearchOptions${
        autocompleteGroupedSearchOptions.length ? '' : ' do not'
      } exist`, () => {
        const mockGetters = {
          defaultSearchOptions,
          scopedSearchOptions,
          autocompleteGroupedSearchOptions,
        };

        beforeEach(() => {
          createState();
          state.search = search;
        });

        it(`should return the correct combined array`, () => {
          expect(getters.searchOptions(state, mockGetters)).toStrictEqual(expectedArray);
        });
      });
    },
  );
});
