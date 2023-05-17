import { GlCollapsibleListbox } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SourceBranchDropdown from '~/jira_connect/branches/components/source_branch_dropdown.vue';
import { BRANCHES_PER_PAGE } from '~/jira_connect/branches/constants';
import getProjectQuery from '~/jira_connect/branches/graphql/queries/get_project.query.graphql';
import { mockProjects } from '../mock_data';

const mockProject = {
  id: 'test',
  repository: {
    branchNames: ['main', 'f-test', 'release'],
    rootRef: 'main',
  },
};
const mockSelectedProject = mockProjects[0];

const mockProjectQueryResponse = {
  data: {
    project: mockProject,
  },
};
const mockGetProjectQuery = jest.fn().mockResolvedValue(mockProjectQueryResponse);
const mockQueryLoading = jest.fn().mockReturnValue(new Promise(() => {}));

describe('SourceBranchDropdown', () => {
  let wrapper;

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  const assertListboxItems = () => {
    const listboxItems = findListbox().props('items');
    expect(listboxItems).toHaveLength(mockProject.repository.branchNames.length);
    expect(listboxItems.map((item) => item.text)).toEqual(mockProject.repository.branchNames);
  };

  function createMockApolloProvider({ getProjectQueryLoading = false } = {}) {
    Vue.use(VueApollo);

    const mockApollo = createMockApollo([
      [getProjectQuery, getProjectQueryLoading ? mockQueryLoading : mockGetProjectQuery],
    ]);

    return mockApollo;
  }

  function createComponent({ mockApollo, props, mountFn = shallowMount } = {}) {
    wrapper = mountFn(SourceBranchDropdown, {
      apolloProvider: mockApollo || createMockApolloProvider(),
      propsData: props,
    });
  }

  describe('when `selectedProject` prop is not specified', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets listbox `disabled` prop to `true`', () => {
      expect(findListbox().props('disabled')).toBe(true);
    });

    describe('when `selectedProject` becomes specified', () => {
      beforeEach(async () => {
        wrapper.setProps({
          selectedProject: mockSelectedProject,
        });

        await waitForPromises();
      });

      it('sets listbox props correctly', () => {
        expect(findListbox().props()).toMatchObject({
          disabled: false,
          loading: false,
          searchable: true,
          searching: false,
          toggleText: 'Select a branch',
        });
      });

      it('renders available source branches as listbox items', () => {
        assertListboxItems();
      });
    });
  });

  describe('when `selectedProject` prop is specified', () => {
    describe('when branches are loading', () => {
      it('sets loading prop to true', () => {
        createComponent({
          mockApollo: createMockApolloProvider({ getProjectQueryLoading: true }),
          props: { selectedProject: mockSelectedProject },
        });
        expect(findListbox().props('loading')).toEqual(true);
      });
    });

    describe('when branches have loaded', () => {
      describe('when searching branches', () => {
        it('triggers a refetch', async () => {
          createComponent({ mountFn: mount, props: { selectedProject: mockSelectedProject } });
          await waitForPromises();
          jest.clearAllMocks();

          const mockSearchTerm = 'mai';
          await findListbox().vm.$emit('search', mockSearchTerm);

          expect(mockGetProjectQuery).toHaveBeenCalledWith({
            branchNamesLimit: BRANCHES_PER_PAGE,
            branchNamesOffset: 0,
            branchNamesSearchPattern: `*${mockSearchTerm}*`,
            projectPath: 'test-path',
          });
        });
      });

      describe('template', () => {
        beforeEach(async () => {
          createComponent({ props: { selectedProject: mockSelectedProject } });
          await waitForPromises();
        });

        it('sets listbox props correctly', () => {
          expect(findListbox().props()).toMatchObject({
            disabled: false,
            loading: false,
            searchable: true,
            searching: false,
            toggleText: 'Select a branch',
          });
        });

        it('omits monospace styling from listbox', () => {
          expect(findListbox().classes()).not.toContain('gl-font-monospace');
        });

        it('renders available source branches as listbox items', () => {
          assertListboxItems();
        });

        it("emits `change` event with the repository's `rootRef` by default", () => {
          expect(wrapper.emitted('change')[0]).toEqual([mockProject.repository.rootRef]);
        });

        describe('when selecting a listbox item', () => {
          it('emits `change` event with the selected branch name', () => {
            const mockBranchName = mockProject.repository.branchNames[1];
            findListbox().vm.$emit('select', mockBranchName);
            expect(wrapper.emitted('change')[1]).toEqual([mockBranchName]);
          });
        });

        describe('when `selectedBranchName` prop is specified', () => {
          const mockBranchName = mockProject.repository.branchNames[2];

          beforeEach(() => {
            wrapper.setProps({
              selectedBranchName: mockBranchName,
            });
          });

          it('sets listbox text to `selectedBranchName` value', () => {
            expect(findListbox().props('toggleText')).toBe(mockBranchName);
          });

          it('adds monospace styling to listbox', () => {
            expect(findListbox().classes()).toContain('gl-font-monospace');
          });
        });
      });
    });
  });
});
