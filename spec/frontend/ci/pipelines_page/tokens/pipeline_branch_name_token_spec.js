import { GlFilteredSearchToken, GlFilteredSearchSuggestion, GlLoadingIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import Api from '~/api';
import PipelineBranchNameToken from '~/ci/pipelines_page/tokens/pipeline_branch_name_token.vue';
import { branches, mockBranchesAfterMap } from 'jest/ci/pipeline_details/mock_data';

describe('Pipeline Branch Name Token', () => {
  let wrapper;

  const findFilteredSearchToken = () => wrapper.findComponent(GlFilteredSearchToken);
  const findAllFilteredSearchSuggestions = () =>
    wrapper.findAllComponents(GlFilteredSearchSuggestion);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const getBranchSuggestions = () =>
    findAllFilteredSearchSuggestions().wrappers.map((w) => w.text());

  const stubs = {
    GlFilteredSearchToken: {
      template: `<div><slot name="suggestions"></slot></div>`,
    },
  };

  const defaultProps = {
    config: {
      type: 'ref',
      icon: 'branch',
      title: 'Branch name',
      unique: true,
      projectId: '21',
      defaultBranchName: null,
      disabled: false,
    },
    value: {
      data: '',
    },
    cursorPosition: 'start',
  };

  const optionsWithDefaultBranchName = (options) => {
    return {
      propsData: {
        ...defaultProps,
        config: {
          ...defaultProps.config,
          defaultBranchName: 'main',
        },
      },
      ...options,
    };
  };

  const createComponent = (options, data) => {
    wrapper = shallowMount(PipelineBranchNameToken, {
      propsData: {
        ...defaultProps,
      },
      data() {
        return {
          ...data,
        };
      },
      ...options,
    });
  };

  beforeEach(() => {
    jest.spyOn(Api, 'branches').mockResolvedValue({ data: branches });

    createComponent();
  });

  it('passes config correctly', () => {
    expect(findFilteredSearchToken().props('config')).toEqual(defaultProps.config);
  });

  it('fetches and sets project branches', () => {
    expect(Api.branches).toHaveBeenCalled();

    expect(wrapper.vm.branches).toEqual(mockBranchesAfterMap);
    expect(findLoadingIcon().exists()).toBe(false);
  });

  describe('displays loading icon correctly', () => {
    it('shows loading icon', () => {
      createComponent({ stubs }, { loading: true });

      expect(findLoadingIcon().exists()).toBe(true);
    });

    it('does not show loading icon', () => {
      createComponent({ stubs }, { loading: false });

      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('shows branches correctly', () => {
    it('renders all branches', () => {
      createComponent({ stubs }, { branches, loading: false });

      expect(findAllFilteredSearchSuggestions()).toHaveLength(branches.length);
    });

    it('renders only the branch searched for', () => {
      const mockBranches = ['main'];
      createComponent({ stubs }, { branches: mockBranches, loading: false });

      expect(findAllFilteredSearchSuggestions()).toHaveLength(mockBranches.length);
    });

    it('shows the default branch first if no branch was searched for', async () => {
      const mockBranches = [{ name: 'branch-1' }];
      jest.spyOn(Api, 'branches').mockResolvedValue({ data: mockBranches });

      createComponent(optionsWithDefaultBranchName({ stubs }), { loading: false });
      await nextTick();
      expect(getBranchSuggestions()).toEqual(['main', 'branch-1']);
    });

    it('does not show the default branch if a search term was provided', async () => {
      const mockBranches = [{ name: 'branch-1' }];
      jest.spyOn(Api, 'branches').mockResolvedValue({ data: mockBranches });

      createComponent(optionsWithDefaultBranchName(), { loading: false });

      findFilteredSearchToken().vm.$emit('input', { data: 'branch-1' });
      await waitForPromises();
      expect(getBranchSuggestions()).toEqual(['branch-1']);
    });

    it('shows the default branch only once if it appears in the results', async () => {
      const mockBranches = [{ name: 'main' }];
      jest.spyOn(Api, 'branches').mockResolvedValue({ data: mockBranches });

      createComponent(optionsWithDefaultBranchName({ stubs }), { loading: false });
      await nextTick();
      expect(getBranchSuggestions()).toEqual(['main']);
    });
  });
});
