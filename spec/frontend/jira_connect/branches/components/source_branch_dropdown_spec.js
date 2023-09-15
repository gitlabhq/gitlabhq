import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import SourceBranchDropdown from '~/jira_connect/branches/components/source_branch_dropdown.vue';
import { BRANCHES_PER_PAGE } from '~/jira_connect/branches/constants';
import getProjectQuery from '~/jira_connect/branches/graphql/queries/get_project.query.graphql';
import {
  mockBranchNames,
  mockBranchNames2,
  mockProjects,
  mockProjectQueryResponse,
} from '../mock_data';

Vue.use(VueApollo);

describe('SourceBranchDropdown', () => {
  let wrapper;

  const mockSelectedProject = mockProjects[0];
  const querySuccessHandler = jest.fn().mockResolvedValue(mockProjectQueryResponse());
  const queryLoadingHandler = jest.fn().mockReturnValue(new Promise(() => {}));

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);

  const assertListboxItems = (branchNames = mockBranchNames) => {
    const listboxItems = findListbox().props('items');
    expect(listboxItems).toHaveLength(branchNames.length);
    expect(listboxItems.map((item) => item.text)).toEqual(branchNames);
  };

  const createComponent = ({ props, handler = querySuccessHandler } = {}) => {
    const mockApollo = createMockApollo([[getProjectQuery, handler]]);

    wrapper = shallowMount(SourceBranchDropdown, {
      apolloProvider: mockApollo,
      propsData: props,
    });
  };

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
          selected: null,
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
          props: { selectedProject: mockSelectedProject },
          handler: queryLoadingHandler,
        });
        expect(findListbox().props('loading')).toBe(true);
      });
    });

    describe('when branches have loaded', () => {
      describe('when searching branches', () => {
        it('triggers a refetch', async () => {
          createComponent({ props: { selectedProject: mockSelectedProject } });
          await waitForPromises();

          const mockSearchTerm = 'mai';
          expect(querySuccessHandler).toHaveBeenCalledTimes(1);

          await findListbox().vm.$emit('search', mockSearchTerm);

          expect(querySuccessHandler).toHaveBeenCalledTimes(2);
          expect(querySuccessHandler).toHaveBeenLastCalledWith({
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
            selected: null,
            toggleText: 'Select a branch',
          });
        });

        it('disables infinite scroll', () => {
          expect(findListbox().props('infiniteScroll')).toBe(false);
        });

        it('omits monospace styling from listbox', () => {
          expect(findListbox().classes()).not.toContain('gl-font-monospace');
        });

        it('renders available source branches as listbox items', () => {
          assertListboxItems();
        });

        it("emits `change` event with the repository's `rootRef` by default", () => {
          expect(wrapper.emitted('change')[0]).toEqual([mockBranchNames[0]]);
        });

        describe('when selecting a listbox item', () => {
          it('emits `change` event with the selected branch name', () => {
            const mockBranchName = mockBranchNames[1];
            findListbox().vm.$emit('select', mockBranchName);
            expect(wrapper.emitted('change')[1]).toEqual([mockBranchName]);
          });
        });

        describe('when `selectedBranchName` prop is specified', () => {
          const mockBranchName = mockBranchNames[2];

          beforeEach(() => {
            wrapper.setProps({
              selectedBranchName: mockBranchName,
            });
          });

          it('sets listbox selected to `selectedBranchName`', () => {
            expect(findListbox().props('selected')).toBe(mockBranchName);
          });

          it('sets listbox text to `selectedBranchName` value', () => {
            expect(findListbox().props('toggleText')).toBe(mockBranchName);
          });

          it('adds monospace styling to listbox', () => {
            expect(findListbox().classes()).toContain('gl-font-monospace');
          });
        });

        describe('when full page of branches returns', () => {
          const fullPageBranchNames = Array(BRANCHES_PER_PAGE)
            .fill(1)
            .map((_, i) => mockBranchNames[i % mockBranchNames.length]);

          beforeEach(async () => {
            createComponent({
              props: { selectedProject: mockSelectedProject },
              handler: () => Promise.resolve(mockProjectQueryResponse(fullPageBranchNames)),
            });
            await waitForPromises();
          });

          it('enables infinite scroll', () => {
            expect(findListbox().props('infiniteScroll')).toBe(true);
          });
        });
      });

      describe('when loading more branches from infinite scroll', () => {
        const queryLoadMoreHandler = jest.fn();

        beforeEach(async () => {
          queryLoadMoreHandler.mockResolvedValueOnce(mockProjectQueryResponse());
          queryLoadMoreHandler.mockResolvedValueOnce(mockProjectQueryResponse(mockBranchNames2));
          createComponent({
            props: { selectedProject: mockSelectedProject },
            handler: queryLoadMoreHandler,
          });

          await waitForPromises();

          await findListbox().vm.$emit('bottom-reached');
        });

        it('sets loading more prop to true', () => {
          expect(findListbox().props('infiniteScrollLoading')).toBe(true);
        });

        it('triggers load more query', () => {
          expect(queryLoadMoreHandler).toHaveBeenLastCalledWith({
            branchNamesLimit: BRANCHES_PER_PAGE,
            branchNamesOffset: 3,
            branchNamesSearchPattern: '*',
            projectPath: 'test-path',
          });
        });

        it('renders available source branches as listbox items', async () => {
          await waitForPromises();

          assertListboxItems([...mockBranchNames, ...mockBranchNames2]);
        });

        it('sets loading more prop to false once done', async () => {
          await waitForPromises();

          expect(findListbox().props('infiniteScrollLoading')).toBe(false);
        });
      });
    });
  });
});
