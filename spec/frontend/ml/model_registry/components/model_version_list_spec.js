import Vue from 'vue';
import VueApollo from 'vue-apollo';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ModelVersionList from '~/ml/model_registry/components/model_version_list.vue';
import SearchableList from '~/ml/model_registry/components/searchable_list.vue';
import ModelVersionRow from '~/ml/model_registry/components/model_version_row.vue';
import getModelVersionsQuery from '~/ml/model_registry/graphql/queries/get_model_versions.query.graphql';
import EmptyState from '~/ml/model_registry/components/empty_state.vue';
import { GRAPHQL_PAGE_SIZE, MODEL_ENTITIES } from '~/ml/model_registry/constants';
import {
  emptyModelVersionsQuery,
  modelVersionsQuery,
  graphqlModelVersions,
  graphqlPageInfo,
} from '../graphql_mock_data';

Vue.use(VueApollo);

describe('ModelVersionList', () => {
  let wrapper;
  let apolloProvider;

  const findSearchableList = () => wrapper.findComponent(SearchableList);
  const findEmptyState = () => wrapper.findComponent(EmptyState);
  const findAllRows = () => wrapper.findAllComponents(ModelVersionRow);

  const mountComponent = ({
    props = {},
    resolver = jest.fn().mockResolvedValue(modelVersionsQuery()),
  } = {}) => {
    const requestHandlers = [[getModelVersionsQuery, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = mountExtended(ModelVersionList, {
      apolloProvider,
      propsData: {
        modelId: 2,
        ...props,
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  describe('when list is loaded and has no data', () => {
    const resolver = jest.fn().mockResolvedValue(emptyModelVersionsQuery);
    beforeEach(async () => {
      mountComponent({ resolver });
      await waitForPromises();
    });

    it('shows empty state', () => {
      expect(findEmptyState().props('entityType')).toBe(MODEL_ENTITIES.modelVersion);
    });
  });

  describe('if load fails, alert', () => {
    beforeEach(async () => {
      const error = new Error('Failure!');
      mountComponent({ resolver: jest.fn().mockRejectedValue(error) });

      await waitForPromises();
    });

    it('is displayed', () => {
      expect(findSearchableList().props('errorMessage')).toBe(
        'Failed to load model versions with error: Failure!',
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

    it('Passes items to list', () => {
      expect(findSearchableList().props('items')).toEqual(graphqlModelVersions);
    });

    it('displays package version rows', () => {
      expect(findAllRows()).toHaveLength(graphqlModelVersions.length);
    });

    it('binds the correct props', () => {
      expect(findAllRows().at(0).props()).toMatchObject({
        modelVersion: expect.objectContaining(graphqlModelVersions[0]),
      });

      expect(findAllRows().at(1).props()).toMatchObject({
        modelVersion: expect.objectContaining(graphqlModelVersions[1]),
      });
    });
  });

  describe('when list requests update', () => {
    const resolver = jest.fn().mockResolvedValue(modelVersionsQuery());

    beforeEach(async () => {
      mountComponent({ resolver });
      await waitForPromises();
    });

    it('when list emits fetch-page fetches the next set of records', async () => {
      findSearchableList().vm.$emit('fetch-page', {
        after: 'eyJpZCI6IjIifQ',
        first: 30,
        id: 'gid://gitlab/Ml::Model/2',
      });

      await waitForPromises();

      expect(resolver).toHaveBeenLastCalledWith(
        expect.objectContaining({ after: graphqlPageInfo.endCursor, first: GRAPHQL_PAGE_SIZE }),
      );
    });
  });
});
