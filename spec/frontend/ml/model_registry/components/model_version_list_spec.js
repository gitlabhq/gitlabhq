import Vue from 'vue';
import VueApollo from 'vue-apollo';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ModelVersionList from '~/ml/model_registry/components/model_version_list.vue';
import SearchableTable from '~/ml/model_registry/components/searchable_table.vue';
import getModelVersionsQuery from '~/ml/model_registry/graphql/queries/get_model_versions.query.graphql';
import EmptyState from '~/ml/model_registry/components/model_list_empty_state.vue';
import { describeSkipVue3, SkipReason } from 'helpers/vue3_conditional';

import {
  emptyModelVersionsQuery,
  modelVersionsQuery,
  graphqlModelVersions,
} from '../graphql_mock_data';

Vue.use(VueApollo);

const skipReason = new SkipReason({
  name: 'ModelVersionList',
  reason: 'OOM on the worker',
  issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/458413',
});

describeSkipVue3(skipReason, () => {
  let wrapper;
  let apolloProvider;

  const findSearchableTable = () => wrapper.findComponent(SearchableTable);
  const findEmptyState = () => wrapper.findComponent(EmptyState);

  const mountComponent = ({
    props = {},
    resolver = jest.fn().mockResolvedValue(modelVersionsQuery()),
    latestVersion = '1.0.0',
  } = {}) => {
    const requestHandlers = [[getModelVersionsQuery, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = mountExtended(ModelVersionList, {
      apolloProvider,
      propsData: {
        modelId: 'gid://gitlab/Ml::Model/2',
        canWriteModelRegistry: true,
        ...props,
      },
      provide: {
        mlflowTrackingUrl: 'path/to/mlflow',
        createModelVersionPath: 'versions/new',
        canWriteModelRegistry: true,
        latestVersion,
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
    const resolver = jest.fn().mockResolvedValue(emptyModelVersionsQuery);
    beforeEach(async () => {
      mountComponent({ resolver, latestVersion: null });
      await waitForPromises();
    });

    it('shows empty state', () => {
      expect(findEmptyState().props()).toMatchObject({
        title: 'Manage versions of your machine learning model',
        description: 'Use versions to track performance, parameters, and metadata',
        primaryText: 'Create model version',
        primaryLink: 'versions/new',
      });
    });

    it('search is hidden', () => {
      expect(findSearchableTable().props()).toMatchObject({
        showSearch: false,
        sortableFields: [
          {
            label: 'Version',
            orderBy: 'version',
          },
          {
            label: 'Created',
            orderBy: 'created_at',
          },
        ],
      });
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
        'Failed to load model versions with error: Failure!',
      );
    });

    it('error is logged in sentry', () => {
      expect(Sentry.captureException).toHaveBeenCalled();
    });
  });

  describe('when list is loaded with data', () => {
    let resolver;

    beforeEach(async () => {
      resolver = jest.fn().mockResolvedValue(modelVersionsQuery());
      mountComponent({ resolver });

      await waitForPromises();
    });

    it('calls query only once on setup', () => {
      expect(resolver).toHaveBeenCalledTimes(1);
    });

    it('Passes items to table', () => {
      expect(findSearchableTable().props('modelVersions')).toEqual(graphqlModelVersions);
    });

    it('displays version rows', () => {
      expect(findSearchableTable().props('modelVersions')).toHaveLength(2);
    });

    it('search is displayed', () => {
      expect(findSearchableTable().props('showSearch')).toBe(true);
    });
  });
});
