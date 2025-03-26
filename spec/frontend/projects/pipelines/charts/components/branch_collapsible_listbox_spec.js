import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox, GlListboxItem, GlBadge } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import BranchCollapsibleListbox from '~/projects/pipelines/charts/components/branch_collapsible_listbox.vue';
import getBranchesOptionsQuery from '~/projects/pipelines/charts/graphql/queries/get_branches_options.query.graphql';
import { createAlert } from '~/alert';

jest.mock('~/alert');

const mockProjectFullPath = 'my-group/my-project';

describe('Pipeline editor branch switcher', () => {
  let wrapper;
  let mockApollo;
  let getBranchesHandler;

  Vue.use(VueApollo);

  const createComponent = ({ props = {} } = {}) => {
    mockApollo = createMockApollo([[getBranchesOptionsQuery, getBranchesHandler]]);

    wrapper = shallowMount(BranchCollapsibleListbox, {
      propsData: {
        projectPath: mockProjectFullPath,
        projectBranchCount: 10,
        ...props,
      },
      apolloProvider: mockApollo,
      stubs: { GlCollapsibleListbox },
    });
  };

  const findGlCollapsibleListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findListboxItem = (i) => wrapper.findAllComponents(GlListboxItem).at(i);

  const mockBranchesResolvedValue = (branchNames = ['main', 'feature-branch']) => {
    getBranchesHandler.mockResolvedValue({
      data: {
        project: {
          id: '1',
          repository: {
            branchNames,
          },
        },
      },
    });
  };

  beforeEach(() => {
    getBranchesHandler = jest.fn();
  });

  describe('when shown', () => {
    beforeEach(() => {
      createComponent();
    });

    it('configures the collapsible listbox', () => {
      expect(findGlCollapsibleListbox().props()).toMatchObject({
        infiniteScroll: false,
        loading: false,
        infiniteScrollLoading: true,
        items: [{ text: 'All branches', value: '' }],
        searchPlaceholder: 'Filter by branch name',
        searchable: true,
        searching: false,
      });
    });
  });

  describe('when options can be fetched', () => {
    beforeEach(() => {
      mockBranchesResolvedValue();
    });

    describe('when fetched', () => {
      beforeEach(async () => {
        createComponent();

        await waitForPromises();
      });

      it('requested branches', () => {
        expect(getBranchesHandler).toHaveBeenCalledWith({
          limit: 10,
          offset: 0,
          fullPath: mockProjectFullPath,
          searchPattern: '*',
        });
      });

      it('renders items', () => {
        expect(findGlCollapsibleListbox().exists()).toBe(true);

        expect(findGlCollapsibleListbox().props('items')).toEqual([
          { text: 'All branches', value: '' },
          { text: 'main', value: 'main' },
          { text: 'feature-branch', value: 'feature-branch' },
        ]);
      });

      describe('when selected', () => {
        it('updates model to "All branches"', () => {
          findGlCollapsibleListbox().vm.$emit('select', '');
          expect(wrapper.emitted('select')[0]).toEqual([null]);
        });

        it('updates model to a branch', () => {
          findGlCollapsibleListbox().vm.$emit('select', 'feature-branch');
          expect(wrapper.emitted('select')[0]).toEqual(['feature-branch']);
        });
      });

      describe.each`
        search                      | searchPattern
        ${'term1'}                  | ${'*term1*'}
        ${'   with whitespaces   '} | ${'*with whitespaces*'}
      `('when a filtering by branches', ({ search, searchPattern }) => {
        beforeEach(() => {
          findGlCollapsibleListbox().vm.$emit('search', search);
        });

        it('fetches filtered list', () => {
          expect(getBranchesHandler).toHaveBeenCalledTimes(2);
          expect(getBranchesHandler).toHaveBeenNthCalledWith(2, {
            limit: 10,
            offset: 0,
            fullPath: mockProjectFullPath,
            searchPattern,
          });
        });
      });

      describe('when the bottom is reached', () => {
        beforeEach(async () => {
          mockBranchesResolvedValue(['feature-branch-2', 'feature-branch-3']);

          findGlCollapsibleListbox().vm.$emit('bottom-reached');

          await waitForPromises();
        });

        it('fetches more branches', () => {
          expect(getBranchesHandler).toHaveBeenCalledTimes(2);
          expect(getBranchesHandler).toHaveBeenNthCalledWith(2, {
            limit: 10,
            offset: 10,
            fullPath: mockProjectFullPath,
            searchPattern: '*',
          });
        });

        it('updates items', () => {
          expect(findGlCollapsibleListbox().props('items')).toEqual([
            { text: 'All branches', value: '' },
            { text: 'main', value: 'main' },
            { text: 'feature-branch', value: 'feature-branch' },
            { text: 'feature-branch-2', value: 'feature-branch-2' },
            { text: 'feature-branch-3', value: 'feature-branch-3' },
          ]);
        });
      });
    });

    describe('with a default branch', () => {
      beforeEach(async () => {
        createComponent({
          props: {
            defaultBranch: 'main',
          },
        });
        await waitForPromises();
      });

      it('marks default branch with a badge', () => {
        expect(findListboxItem(1).text()).toMatch('main');
        expect(findListboxItem(1).findComponent(GlBadge).text()).toBe('default');
      });
    });

    describe('when a branch is selected', () => {
      beforeEach(async () => {
        createComponent({
          props: {
            selected: 'feature-branch',
          },
        });
        await waitForPromises();
      });

      it('shows selected branch', () => {
        expect(findGlCollapsibleListbox().props('selected')).toBe('feature-branch');
        expect(findGlCollapsibleListbox().props('toggleText')).toBe('feature-branch');

        expect(findListboxItem(2).text()).toBe('feature-branch');
        expect(findListboxItem(2).props('isSelected')).toBe(true);
      });
    });
  });

  describe('when options cannot be fetched', () => {
    beforeEach(async () => {
      getBranchesHandler.mockRejectedValue(new Error('Error!'));

      createComponent();
      await waitForPromises();
    });

    it('shows "All" option', () => {
      expect(findGlCollapsibleListbox().props('items')).toEqual([
        { text: 'All branches', value: '' },
      ]);
    });

    it('shows an error message', () => {
      expect(createAlert).toHaveBeenCalledTimes(1);
      expect(createAlert).toHaveBeenCalledWith({
        captureError: true,
        error: new Error('Error!'),
        message: 'Unable to fetch branch list for this project.',
      });
    });
  });
});
