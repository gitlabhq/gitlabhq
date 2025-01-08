import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { GlEmptyState, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GlobalSearchResultsEmpty from '~/search/results/components/result_empty.vue';
import { MOCK_QUERY } from '../../mock_data';

Vue.use(Vuex);

describe('GlobalSearchResultsEmpty', () => {
  let wrapper;
  let state;

  const getterSpies = {
    currentScope: jest.fn(() => 'blobs'),
  };

  const normalizeWhitespace = (str) => str.replace(/\s+/g, ' ').trim();

  const createComponent = (props, initialState = {}) => {
    state = {
      query: { ...MOCK_QUERY, scope: 'blobs' },
      searchType: 'zoekt',
      projectInitialJson: {
        full_path: 'test/test',
        name_with_namespace: 'test / test',
      },
      groupInitialJson: {
        full_path: 'test_group/test_sub_group',
        full_name: 'test group / test sub-group',
      },
      ...initialState,
    };

    const store = new Vuex.Store({
      state,
      getters: getterSpies,
    });

    wrapper = shallowMountExtended(GlobalSearchResultsEmpty, {
      store,
      propsData: {
        ...props,
      },
      stubs: {
        GlSprintf,
        GlEmptyState,
      },
    });
  };

  const findParagraph = () => wrapper.find('p');

  describe('when project id', () => {
    beforeEach(() => {
      createComponent({}, { query: { group_id: undefined, project_id: 1, search: 'test' } });
    });

    it(`renders all parts of header`, () => {
      expect(normalizeWhitespace(findParagraph().text())).toMatch(
        "We couldn't find any Code matching test in project test / test",
      );
    });
  });

  describe('when group id', () => {
    beforeEach(() => {
      createComponent({}, { query: { group_id: 1, project_id: undefined, search: 'test' } });
    });

    it(`renders all parts of header`, () => {
      expect(normalizeWhitespace(findParagraph().text())).toMatch(
        "We couldn't find any Code matching test in group test group / test sub-group",
      );
    });
  });

  describe('when no group or project', () => {
    beforeEach(() => {
      createComponent(
        {},
        { query: { group_id: undefined, project_id: undefined, search: 'test' } },
      );
    });

    it(`renders all parts of header`, () => {
      expect(normalizeWhitespace(findParagraph().text())).toMatch(
        "We couldn't find any Code matching test",
      );
    });
  });
});
