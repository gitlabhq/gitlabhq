import { GlDropdown, GlDropdownItem, GlLoadingIcon, GlSearchBoxByType } from '@gitlab/ui';
import { mount, shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import SourceBranchDropdown from '~/jira_connect/branches/components/source_branch_dropdown.vue';
import { BRANCHES_PER_PAGE } from '~/jira_connect/branches/constants';
import getProjectQuery from '~/jira_connect/branches/graphql/queries/get_project.query.graphql';

const localVue = createLocalVue();

const mockProject = {
  id: 'test',
  fullPath: 'test-path',
  repository: {
    branchNames: ['main', 'f-test', 'release'],
    rootRef: 'main',
  },
};

const mockProjectQueryResponse = {
  data: {
    project: mockProject,
  },
};
const mockGetProjectQuery = jest.fn().mockResolvedValue(mockProjectQueryResponse);
const mockQueryLoading = jest.fn().mockReturnValue(new Promise(() => {}));

describe('SourceBranchDropdown', () => {
  let wrapper;

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findAllDropdownItems = () => wrapper.findAllComponents(GlDropdownItem);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findDropdownItemByText = (text) =>
    findAllDropdownItems().wrappers.find((item) => item.text() === text);
  const findSearchBox = () => wrapper.findComponent(GlSearchBoxByType);

  const assertDropdownItems = () => {
    const dropdownItems = findAllDropdownItems();
    expect(dropdownItems.wrappers).toHaveLength(mockProject.repository.branchNames.length);
    expect(dropdownItems.wrappers.map((item) => item.text())).toEqual(
      mockProject.repository.branchNames,
    );
  };

  function createMockApolloProvider({ getProjectQueryLoading = false } = {}) {
    localVue.use(VueApollo);

    const mockApollo = createMockApollo([
      [getProjectQuery, getProjectQueryLoading ? mockQueryLoading : mockGetProjectQuery],
    ]);

    return mockApollo;
  }

  function createComponent({ mockApollo, props, mountFn = shallowMount } = {}) {
    wrapper = mountFn(SourceBranchDropdown, {
      localVue,
      apolloProvider: mockApollo || createMockApolloProvider(),
      propsData: props,
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when `selectedProject` prop is not specified', () => {
    beforeEach(() => {
      createComponent();
    });

    it('sets dropdown `disabled` prop to `true`', () => {
      expect(findDropdown().props('disabled')).toBe(true);
    });

    describe('when `selectedProject` becomes specified', () => {
      beforeEach(async () => {
        wrapper.setProps({
          selectedProject: mockProject,
        });

        await waitForPromises();
      });

      it('sets dropdown props correctly', () => {
        expect(findDropdown().props()).toMatchObject({
          loading: false,
          disabled: false,
          text: 'Select a branch',
        });
      });

      it('renders available source branches as dropdown items', () => {
        assertDropdownItems();
      });
    });
  });

  describe('when `selectedProject` prop is specified', () => {
    describe('when branches are loading', () => {
      it('renders loading icon in dropdown', () => {
        createComponent({
          mockApollo: createMockApolloProvider({ getProjectQueryLoading: true }),
          props: { selectedProject: mockProject },
        });

        expect(findLoadingIcon().isVisible()).toBe(true);
      });
    });

    describe('when branches have loaded', () => {
      describe('when searching branches', () => {
        it('triggers a refetch', async () => {
          createComponent({ mountFn: mount, props: { selectedProject: mockProject } });
          await waitForPromises();
          jest.clearAllMocks();

          const mockSearchTerm = 'mai';
          await findSearchBox().vm.$emit('input', mockSearchTerm);

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
          createComponent({ props: { selectedProject: mockProject } });
          await waitForPromises();
        });

        it('sets dropdown props correctly', () => {
          expect(findDropdown().props()).toMatchObject({
            loading: false,
            disabled: false,
            text: 'Select a branch',
          });
        });

        it('omits monospace styling from dropdown', () => {
          expect(findDropdown().classes()).not.toContain('gl-font-monospace');
        });

        it('renders available source branches as dropdown items', () => {
          assertDropdownItems();
        });

        it("emits `change` event with the repository's `rootRef` by default", () => {
          expect(wrapper.emitted('change')[0]).toEqual([mockProject.repository.rootRef]);
        });

        describe('when selecting a dropdown item', () => {
          it('emits `change` event with the selected branch name', async () => {
            const mockBranchName = mockProject.repository.branchNames[1];
            const itemToSelect = findDropdownItemByText(mockBranchName);
            await itemToSelect.vm.$emit('click');

            expect(wrapper.emitted('change')[1]).toEqual([mockBranchName]);
          });
        });

        describe('when `selectedBranchName` prop is specified', () => {
          const mockBranchName = mockProject.repository.branchNames[2];

          beforeEach(async () => {
            wrapper.setProps({
              selectedBranchName: mockBranchName,
            });
          });

          it('sets `isChecked` prop of the corresponding dropdown item to `true`', () => {
            expect(findDropdownItemByText(mockBranchName).props('isChecked')).toBe(true);
          });

          it('sets dropdown text to `selectedBranchName` value', () => {
            expect(findDropdown().props('text')).toBe(mockBranchName);
          });

          it('adds monospace styling to dropdown', () => {
            expect(findDropdown().classes()).toContain('gl-font-monospace');
          });
        });
      });
    });
  });
});
