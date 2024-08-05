import { GlAlert, GlKeysetPagination, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import EmptyState from '~/terraform/components/empty_state.vue';
import StatesTable from '~/terraform/components/states_table.vue';
import TerraformList from '~/terraform/components/terraform_list.vue';
import getStatesQuery from '~/terraform/graphql/queries/get_states.query.graphql';

Vue.use(VueApollo);

describe('TerraformList', () => {
  let wrapper;

  const propsData = {
    emptyStateImage: '/path/to/image',
  };

  const provide = {
    projectPath: 'path/to/project',
  };

  const createWrapper = ({ terraformStates, queryResponse = null }) => {
    const apolloQueryResponse = {
      data: {
        project: {
          id: '1',
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
      apolloProvider,
      propsData,
      provide,
      stubs: {
        CrudComponent,
      },
    });
  };

  const findEmptyState = () => wrapper.findComponent(EmptyState);
  const findPaginationButtons = () => wrapper.findComponent(GlKeysetPagination);
  const findStatesTable = () => wrapper.findComponent(StatesTable);
  const findCrudComponent = () => wrapper.findComponent(CrudComponent);

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
              __typename: 'PageInfo',
              hasNextPage: true,
              hasPreviousPage: false,
              startCursor: 'prev',
              endCursor: 'next',
            },
          },
        });

        return waitForPromises();
      });

      it('displays a terraform states card and count', () => {
        expect(findCrudComponent().props('title')).toBe('Terraform states');
        expect(findCrudComponent().props('count')).toBe(2);
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

      it('displays a terraform states card with no count', () => {
        expect(findCrudComponent().props('title')).toBe('Terraform states');
        expect(findCrudComponent().props('count')).toBe(0);
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
      expect(wrapper.findComponent(GlAlert).exists()).toBe(true);
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
      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
    });
  });
});
