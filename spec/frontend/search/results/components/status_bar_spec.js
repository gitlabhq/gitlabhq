import { GlSprintf, GlLink } from '@gitlab/ui';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GlobalSearchStatusBar from '~/search/results/components/status_bar.vue';
import { MOCK_QUERY } from '../../mock_data';

Vue.use(Vuex);

describe('GlobalSearchStatusBar', () => {
  let wrapper;

  const defaultProps = {
    blobSearch: {
      perPage: 20,
      fileCount: 1074,
      matchCount: 3000,
    },
    hasError: false,
    hasResults: true,
    isLoading: false,
  };

  const defaultState = {
    query: {
      ...MOCK_QUERY,
      group_id: null,
      project_id: null,
      search: 'test',
    },
    projectInitialJson: {},
    groupInitialJson: {},
    repositoryRef: 'main',
  };

  const groupInitialJson = {
    id: 1,
    name: 'group-name',
    full_name: 'Group Full Name',
    full_path: 'group-full-path',
  };

  const projectInitialJson = {
    id: 1,
    name: 'project-name',
    name_with_namespace: 'Project with Namespace',
    full_path: 'group-full-path/project-path',
  };

  const createComponent = ({ propsData = {}, initialState = {} } = {}) => {
    const store = new Vuex.Store({
      state: {
        ...defaultState,
        ...initialState,
      },
    });

    wrapper = shallowMountExtended(GlobalSearchStatusBar, {
      propsData: {
        ...defaultProps,
        ...propsData,
      },
      store,
      stubs: {
        GlSprintf,
      },
    });
  };

  const findGlLink = () => wrapper.findComponent(GlLink);

  describe('simple status message', () => {
    describe('multiple results', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the status bar', () => {
        expect(wrapper.text()).toContain('Showing 3000 code results for test');
      });
    });

    describe('one result status message', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            blobSearch: {
              perPage: 20,
              fileCount: 1,
              matchCount: 1,
            },
          },
        });
      });

      it('renders the status bar', () => {
        expect(wrapper.text()).toContain('Showing 1 code result for test');
      });
    });
  });
  describe('group status message', () => {
    describe('multiple results', () => {
      beforeEach(() => {
        createComponent({
          initialState: {
            query: {
              ...MOCK_QUERY,
              group_id: 1,
              project_id: null,
              search: 'test',
            },
            groupInitialJson,
          },
        });
      });

      it('renders the status bar', () => {
        expect(wrapper.text()).toContain(
          'Showing 3000 code results for test in group Group Full Name',
        );
      });

      it('renders link with proper url', () => {
        expect(findGlLink().attributes('href')).toBe('http://test.host/group-full-path');
      });
    });
    describe('single result', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            blobSearch: {
              perPage: 20,
              fileCount: 1,
              matchCount: 1,
            },
          },
          initialState: {
            query: {
              ...MOCK_QUERY,
              group_id: 1,
              project_id: null,
              search: 'test',
            },
            groupInitialJson,
          },
        });
      });

      it('renders the status bar', () => {
        expect(wrapper.text()).toContain('Showing 1 code result for test in group Group Full Name');
      });

      it('renders link with proper url', () => {
        expect(findGlLink().attributes('href')).toBe('http://test.host/group-full-path');
      });
    });
  });

  describe('project status message', () => {
    describe('multiple results', () => {
      beforeEach(() => {
        createComponent({
          initialState: {
            query: {
              ...MOCK_QUERY,
              group_id: null,
              project_id: 1,
              search: 'test',
            },
            projectInitialJson,
          },
        });
      });

      it('renders the status bar', () => {
        expect(wrapper.text()).toContain(
          'Showing 3000 code results for test in  of Project with Namespace',
        );
      });

      it('renders link with proper url', () => {
        expect(findGlLink().attributes('href')).toBe(
          'http://test.host/group-full-path/project-path',
        );
      });
    });
    describe('single result', () => {
      beforeEach(() => {
        createComponent({
          propsData: {
            blobSearch: {
              perPage: 20,
              fileCount: 1,
              matchCount: 1,
            },
          },
          initialState: {
            query: {
              ...MOCK_QUERY,
              group_id: null,
              project_id: 1,
              search: 'test',
            },
            projectInitialJson,
          },
        });
      });

      it('renders the status bar', () => {
        expect(wrapper.text()).toContain(
          'Showing 1 code result for test in  of Project with Namespace',
        );
      });

      it('renders link with proper url', () => {
        expect(findGlLink().attributes('href')).toBe(
          'http://test.host/group-full-path/project-path',
        );
      });
    });
  });

  describe('when there are no results', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          hasResults: false,
        },
      });
    });

    it('does not render the status bar', () => {
      expect(wrapper.text()).toBe('');
    });
  });

  describe('when loading', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          isLoading: true,
        },
      });
    });

    it('does not render the status bar', () => {
      expect(wrapper.text()).toBe('');
    });
  });
});
