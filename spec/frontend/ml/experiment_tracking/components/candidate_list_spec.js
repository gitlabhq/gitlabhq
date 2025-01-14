import Vue from 'vue';
import { GlEmptyState, GlButton } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { mount } from '@vue/test-utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CandidateList from '~/ml/experiment_tracking/components/candidate_list.vue';
import SearchableTable from '~/ml/model_registry/components/searchable_table.vue';
import getExperimentCandidates from '~/ml/experiment_tracking/graphql/queries/get_experiment_candidates.query.graphql';
import { GRAPHQL_PAGE_SIZE } from '~/ml/experiment_tracking/constants';
import {
  emptyCandidateQuery,
  experimentCandidatesQuery,
} from 'jest/ml/experiment_tracking/graphql_mock_data';
import { graphqlCandidates, graphqlPageInfo } from 'jest/ml/model_registry/graphql_mock_data';

Vue.use(VueApollo);

describe('ml/model_registry/components/candidate_list.vue', () => {
  let wrapper;
  let apolloProvider;

  const findSearchableTable = () => wrapper.findComponent(SearchableTable);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const mountComponent = ({
    props = {
      experimentId: 'gid://gitlab/Ml::Experiment/1',
    },
    resolver = jest.fn().mockResolvedValue(experimentCandidatesQuery()),
  } = {}) => {
    const requestHandlers = [[getExperimentCandidates, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = mount(CandidateList, {
      apolloProvider,
      propsData: {
        experimentId: 'gid://gitlab/Ml::Experiment/1',
        ...props,
      },
      stubs: {
        SearchableTable,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  describe('when list is loaded and has no data', () => {
    const resolver = jest.fn().mockResolvedValue(emptyCandidateQuery);
    beforeEach(async () => {
      mountComponent({ resolver });
      await waitForPromises();
    });

    it('shows empty state', () => {
      expect(findEmptyState().props('description')).toBe(
        'Use candidates to track performance, parameters, and metadata',
      );
      expect(findEmptyState().props('title')).toBe('No candidates associated with this experiment');
      expect(findEmptyState().findComponent(GlButton).attributes('href')).toBe(
        '/help/user/project/ml/experiment_tracking/mlflow_client.md#logging-runs-to-a-model',
      );
    });
  });

  describe('if load fails, alert', () => {
    beforeEach(async () => {
      const error = new Error('Failure!');
      mountComponent({ resolver: jest.fn().mockRejectedValue(error) });

      await waitForPromises();
    });

    it('is displayed', () => {
      expect(findSearchableTable().props('errorMessage')).toBe(
        'Failed to load experiment candidates with error: Failure!',
      );
    });

    it('error is logged in sentry', () => {
      expect(Sentry.captureException).toHaveBeenCalled();
    });
  });

  describe('when list is loaded with data', () => {
    beforeEach(async () => {
      mountComponent();
      await waitForPromises();
    });

    it('does not show emptystate', () => {
      expect(findEmptyState().exists()).toBe(false);
    });

    it('Passes items to list', () => {
      expect(findSearchableTable().props('candidates')).toEqual(graphqlCandidates);
    });

    it('displays candidate rows', () => {
      expect(findSearchableTable().props('candidates')).toHaveLength(graphqlCandidates.length);
    });

    it('binds the correct props', () => {
      expect(findSearchableTable().props('candidates')).toEqual(graphqlCandidates);
    });
  });

  describe('when list requests update', () => {
    const resolver = jest.fn().mockResolvedValue(experimentCandidatesQuery());

    beforeEach(async () => {
      mountComponent({ resolver });
      await waitForPromises();
    });

    it('calls query only once on setup', () => {
      expect(resolver).toHaveBeenCalledTimes(1);
    });

    it('when list emits fetch-page fetches the next set of records', async () => {
      findSearchableTable().vm.$emit('fetch-page', {
        after: 'eyJpZCI6IjIifQ',
        first: 30,
        id: 'gid://gitlab/Ml::Model/2',
      });

      await waitForPromises();

      expect(resolver).toHaveBeenLastCalledWith({
        after: graphqlPageInfo.endCursor,
        first: GRAPHQL_PAGE_SIZE,
        id: 'gid://gitlab/Ml::Model/2',
      });
    });
  });
});
