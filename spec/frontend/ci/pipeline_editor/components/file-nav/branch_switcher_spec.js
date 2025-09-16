import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { visitUrl } from '~/lib/utils/url_utility';
import createMockApollo from 'helpers/mock_apollo_helper';
import BranchSwitcher from '~/ci/pipeline_editor/components/file_nav/branch_switcher.vue';
import BranchSelector from '~/ci/pipeline_editor/components/shared/branch_selector.vue';
import { DEFAULT_FAILURE } from '~/ci/pipeline_editor/constants';
import getCurrentBranch from '~/ci/pipeline_editor/graphql/queries/client/current_branch.query.graphql';
import { resolvers } from '~/ci/pipeline_editor/graphql/resolvers';

import {
  mockBranchPaginationLimit,
  mockDefaultBranch,
  mockProjectFullPath,
  mockTotalBranches,
} from '../../mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn().mockName('visitUrlMock'),
}));

describe('Pipeline editor branch switcher', () => {
  let wrapper;
  let mockApollo;

  Vue.use(VueApollo);

  const createComponent = ({ props = {} } = {}) => {
    const handlers = [];
    mockApollo = createMockApollo(handlers, resolvers);

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getCurrentBranch,
      data: {
        workBranches: {
          __typename: 'BranchList',
          current: {
            __typename: 'WorkBranch',
            name: mockDefaultBranch,
          },
        },
      },
    });

    wrapper = shallowMount(BranchSwitcher, {
      propsData: {
        ...props,
        paginationLimit: mockBranchPaginationLimit,
      },
      provide: {
        projectFullPath: mockProjectFullPath,
        totalBranches: mockTotalBranches,
      },
      apolloProvider: mockApollo,
    });
  };

  const findBranchSelector = () => wrapper.findComponent(BranchSelector);

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders branch selector', () => {
      expect(findBranchSelector().props()).toEqual({
        dropdownHeader: 'Switch branch',
        currentBranchName: mockDefaultBranch,
        paginationLimit: mockBranchPaginationLimit,
      });
    });
  });

  describe('on fetch error', () => {
    beforeEach(() => {
      createComponent();
      findBranchSelector().vm.$emit('fetch-error');
    });

    it('shows an error message', () => {
      expect(wrapper.emitted('showError')).toBeDefined();
      expect(wrapper.emitted('showError')[0]).toEqual([
        {
          reasons: ['Unable to fetch branch list for this project.'],
          type: DEFAULT_FAILURE,
        },
      ]);
    });
  });

  describe('when switching branches', () => {
    const newBranch = 'new-branch';

    beforeEach(() => {
      createComponent();
    });

    it('reloads the page with the correct branch when selecting a different branch', () => {
      findBranchSelector().vm.$emit('select-branch', newBranch);

      expect(visitUrl).toHaveBeenCalled();
      expect(visitUrl.mock.calls[0][0]).toContain(`?branch_name=${newBranch}`);
    });

    describe('with unsaved changes', () => {
      beforeEach(() => {
        createComponent({ props: { hasUnsavedChanges: true } });
      });

      it('emits `select-branch` event and does not switch branch', () => {
        expect(wrapper.emitted('select-branch')).toBeUndefined();

        findBranchSelector().vm.$emit('select-branch', newBranch);

        expect(wrapper.emitted('select-branch')).toEqual([[newBranch]]);
        expect(wrapper.emitted('refetchContent')).toBeUndefined();
      });
    });
  });
});
