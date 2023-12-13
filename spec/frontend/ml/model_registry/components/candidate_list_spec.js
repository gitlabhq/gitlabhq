import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CandidateList from '~/ml/model_registry/components/candidate_list.vue';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import CandidateListRow from '~/ml/model_registry/components/candidate_list_row.vue';
import getModelCandidatesQuery from '~/ml/model_registry/graphql/queries/get_model_candidates.query.graphql';
import { GRAPHQL_PAGE_SIZE } from '~/ml/model_registry/constants';
import {
  emptyCandidateQuery,
  modelCandidatesQuery,
  graphqlCandidates,
  graphqlPageInfo,
} from '../graphql_mock_data';

Vue.use(VueApollo);

describe('ml/model_registry/components/candidate_list.vue', () => {
  let wrapper;
  let apolloProvider;

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findLoader = () => wrapper.findComponent(PackagesListLoader);
  const findRegistryList = () => wrapper.findComponent(RegistryList);
  const findListRow = () => wrapper.findComponent(CandidateListRow);
  const findAllRows = () => wrapper.findAllComponents(CandidateListRow);

  const mountComponent = ({
    props = {},
    resolver = jest.fn().mockResolvedValue(modelCandidatesQuery()),
  } = {}) => {
    const requestHandlers = [[getModelCandidatesQuery, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMount(CandidateList, {
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
    const resolver = jest.fn().mockResolvedValue(emptyCandidateQuery);
    beforeEach(async () => {
      mountComponent({ resolver });
      await waitForPromises();
    });

    it('displays empty slot message', () => {
      expect(wrapper.text()).toContain('This model has no candidates');
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
      expect(findAlert().text()).toContain('Failed to load model candidates with error: Failure!');
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
        items: graphqlCandidates,
        pagination: {},
        isLoading: false,
        hiddenDelete: true,
      });
    });

    it('displays candidate rows', () => {
      expect(findAllRows().exists()).toEqual(true);
      expect(findAllRows()).toHaveLength(graphqlCandidates.length);
    });

    it('binds the correct props', () => {
      expect(findAllRows().at(0).props()).toMatchObject({
        candidate: expect.objectContaining(graphqlCandidates[0]),
      });

      expect(findAllRows().at(1).props()).toMatchObject({
        candidate: expect.objectContaining(graphqlCandidates[1]),
      });
    });

    it('does not display loader', () => {
      expect(findLoader().exists()).toBe(false);
    });

    it('does not display empty message', () => {
      expect(findAlert().exists()).toBe(false);
    });
  });

  describe('when user interacts with pagination', () => {
    const resolver = jest.fn().mockResolvedValue(modelCandidatesQuery());

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
