import { GlAlert, GlBadge, GlKeysetPagination, GlLoadingIcon, GlTab } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import EmptyState from '~/terraform/components/empty_state.vue';
import StatesTable from '~/terraform/components/states_table.vue';
import TerraformList from '~/terraform/components/terraform_list.vue';
import getStatesQuery from '~/terraform/graphql/queries/get_states.query.graphql';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('TerraformList', () => {
  let wrapper;

  const propsData = {
    emptyStateImage: '/path/to/image',
    projectPath: 'path/to/project',
  };

  const createWrapper = ({ terraformStates, queryResponse = null }) => {
    const apolloQueryResponse = {
      data: {
        project: {
          terraformStates,
        },
      },
    };

    const mockResolvers = {
      TerraformState: {
        _showDetails: jest.fn().mockResolvedValue(false),
        errorMessages: jest.fn().mockResolvedValue([]),
        loadingLock: jest.fn().mockResolvedValue(false),
        loadingRemove: jest.fn().mockResolvedValue(false),
      },
      Mutation: {
        addDataToTerraformState: jest.fn().mockResolvedValue({}),
      },
    };

    const statsQueryResponse = queryResponse || jest.fn().mockResolvedValue(apolloQueryResponse);
    const apolloProvider = createMockApollo([[getStatesQuery, statsQueryResponse]], mockResolvers);

    wrapper = shallowMount(TerraformList, {
      localVue,
      apolloProvider,
      propsData,
      stubs: {
        GlTab,
      },
    });
  };

  const findBadge = () => wrapper.find(GlBadge);
  const findEmptyState = () => wrapper.find(EmptyState);
  const findPaginationButtons = () => wrapper.find(GlKeysetPagination);
  const findStatesTable = () => wrapper.find(StatesTable);
  const findTab = () => wrapper.find(GlTab);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when the terraform query has succeeded', () => {
    describe('when there is a list of terraform states', () => {
      const states = [
        {
          _showDetails: false,
          errorMessages: [],
          id: 'gid://gitlab/Terraform::State/1',
          name: 'state-1',
          latestVersion: null,
          loadingLock: false,
          loadingRemove: false,
          lockedAt: null,
          lockedByUser: null,
          updatedAt: null,
        },
        {
          _showDetails: false,
          errorMessages: [],
          id: 'gid://gitlab/Terraform::State/2',
          name: 'state-2',
          latestVersion: null,
          loadingLock: false,
          loadingRemove: false,
          lockedAt: null,
          lockedByUser: null,
          updatedAt: null,
        },
      ];

      beforeEach(() => {
        createWrapper({
          terraformStates: {
            nodes: states,
            count: states.length,
            pageInfo: {
              hasNextPage: true,
              hasPreviousPage: false,
              startCursor: 'prev',
              endCursor: 'next',
            },
          },
        });

        return waitForPromises();
      });

      it('displays a states tab and count', () => {
        expect(findTab().text()).toContain('States');
        expect(findBadge().text()).toBe('2');
      });

      it('renders the states table and pagination buttons', () => {
        expect(findStatesTable().exists()).toBe(true);
        expect(findPaginationButtons().exists()).toBe(true);
      });

      describe('when list has no additional pages', () => {
        beforeEach(() => {
          createWrapper({
            terraformStates: {
              nodes: states,
              count: states.length,
              pageInfo: {
                hasNextPage: false,
                hasPreviousPage: false,
                startCursor: '',
                endCursor: '',
              },
            },
          });

          return waitForPromises();
        });

        it('renders the states table without pagination buttons', () => {
          expect(findStatesTable().exists()).toBe(true);
          expect(findPaginationButtons().exists()).toBe(false);
        });
      });
    });

    describe('when the list of terraform states is empty', () => {
      beforeEach(() => {
        createWrapper({
          terraformStates: {
            nodes: [],
            count: 0,
            pageInfo: null,
          },
        });

        return waitForPromises();
      });

      it('displays a states tab with no count', () => {
        expect(findTab().text()).toContain('States');
        expect(findBadge().exists()).toBe(false);
      });

      it('renders the empty state', () => {
        expect(findEmptyState().exists()).toBe(true);
      });
    });
  });

  describe('when the terraform query has errored', () => {
    beforeEach(() => {
      createWrapper({ terraformStates: null, queryResponse: jest.fn().mockRejectedValue() });

      return waitForPromises();
    });

    it('displays an alert message', () => {
      expect(wrapper.find(GlAlert).exists()).toBe(true);
    });
  });

  describe('when the terraform query is loading', () => {
    beforeEach(() => {
      createWrapper({
        terraformStates: null,
        queryResponse: jest.fn().mockReturnValue(new Promise(() => {})),
      });
    });

    it('displays a loading icon', () => {
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
    });
  });
});
