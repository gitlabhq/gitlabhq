import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mount } from '@vue/test-utils';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CandidateList from '~/ml/model_registry/components/candidate_list.vue';
import SearchableList from '~/ml/model_registry/components/searchable_list.vue';
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

  const findSearchableList = () => wrapper.findComponent(SearchableList);
  const findAllRows = () => wrapper.findAllComponents(CandidateListRow);

  const mountComponent = ({
    props = {},
    resolver = jest.fn().mockResolvedValue(modelCandidatesQuery()),
  } = {}) => {
    const requestHandlers = [[getModelCandidatesQuery, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = mount(CandidateList, {
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
    const resolver = jest.fn().mockResolvedValue(emptyCandidateQuery);
    beforeEach(async () => {
      mountComponent({ resolver });
      await waitForPromises();
    });

    it('shows empty state', () => {
      expect(wrapper.text()).toContain('This model has no candidates');
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
        'Failed to load model candidates with error: Failure!',
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
      expect(findSearchableList().props('items')).toEqual(graphqlCandidates);
    });

    it('displays package version rows', () => {
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
  });

  describe('when list requests update', () => {
    const resolver = jest.fn().mockResolvedValue(modelCandidatesQuery());

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
