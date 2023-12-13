import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ModelVersionList from '~/ml/model_registry/components/model_version_list.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
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

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLoader = () => wrapper.findComponent(PackagesListLoader);
  const findRegistryList = () => wrapper.findComponent(RegistryList);
  const findEmptyState = () => wrapper.findComponent(EmptyState);
  const findListRow = () => wrapper.findComponent(ModelVersionRow);
  const findAllRows = () => wrapper.findAllComponents(ModelVersionRow);

  const mountComponent = ({
    props = {},
    resolver = jest.fn().mockResolvedValue(modelVersionsQuery()),
  } = {}) => {
    const requestHandlers = [[getModelVersionsQuery, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(ModelVersionList, {
      apolloProvider,
      propsData: {
        modelId: 2,
        ...props,
      },
      stubs: {
        RegistryList,
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

    it('does not display loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('does not display rows', () => {
      expect(findListRow().exists()).toBe(false);
    });

    it('does not display registry list', () => {
      expect(findRegistryList().exists()).toBe(false);
    });

    it('does not display alert', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('if load fails, alert', () => {
    beforeEach(async () => {
      const error = new Error('Failure!');
      mountComponent({ resolver: jest.fn().mockRejectedValue(error) });

      await waitForPromises();
    });

    it('is displayed', () => {
      expect(findAlert().exists()).toBe(true);
    });

    it('shows error message', () => {
      expect(findAlert().text()).toContain('Failed to load model versions with error: Failure!');
    });

    it('is not dismissible', () => {
      expect(findAlert().props('dismissible')).toBe(false);
    });

    it('is of variant danger', () => {
      expect(findAlert().attributes('variant')).toBe('danger');
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

    it('displays package registry list', () => {
      expect(findRegistryList().exists()).toEqual(true);
    });

    it('binds the right props', () => {
      expect(findRegistryList().props()).toMatchObject({
        items: graphqlModelVersions,
        pagination: {},
        isLoading: false,
        hiddenDelete: true,
      });
    });

    it('displays package version rows', () => {
      expect(findAllRows().exists()).toEqual(true);
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

    it('does not display loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('does not display empty state', () => {
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('when user interacts with pagination', () => {
    const resolver = jest.fn().mockResolvedValue(modelVersionsQuery());

    beforeEach(async () => {
      mountComponent({ resolver });
      await waitForPromises();
    });

    it('when list emits next-page fetches the next set of records', async () => {
      findRegistryList().vm.$emit('next-page');
      await waitForPromises();

      expect(resolver).toHaveBeenLastCalledWith(
        expect.objectContaining({ after: graphqlPageInfo.endCursor, first: GRAPHQL_PAGE_SIZE }),
      );
    });

    it('when list emits prev-page fetches the prev set of records', async () => {
      findRegistryList().vm.$emit('prev-page');
      await waitForPromises();

      expect(resolver).toHaveBeenLastCalledWith(
        expect.objectContaining({ before: graphqlPageInfo.startCursor, last: GRAPHQL_PAGE_SIZE }),
      );
    });
  });
});
