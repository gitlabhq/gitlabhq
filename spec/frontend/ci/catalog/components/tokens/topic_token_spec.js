import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import TopicToken from '~/ci/catalog/components/tokens/topic_token.vue';
import BaseToken from '~/vue_shared/components/filtered_search_bar/tokens/base_token.vue';
import searchProjectTopics from '~/graphql_shared/queries/project_topics_search.query.graphql';

Vue.use(VueApollo);

jest.mock('~/alert');

const mockTopics = [
  { id: 'gid://gitlab/Projects::Topic/1', name: 'ruby', title: 'Ruby', avatarUrl: null },
  { id: 'gid://gitlab/Projects::Topic/2', name: 'ci-cd', title: 'CI/CD', avatarUrl: null },
  { id: 'gid://gitlab/Projects::Topic/3', name: 'devops', title: 'DevOps', avatarUrl: null },
];

const mockTopicsResponse = {
  data: {
    topics: {
      nodes: mockTopics,
    },
  },
};

describe('TopicToken', () => {
  let wrapper;
  let queryHandler;

  const defaultProps = {
    config: { type: 'topic', multiSelect: true },
    value: { data: '', operator: '||' },
    active: false,
  };

  const findBaseToken = () => wrapper.findComponent(BaseToken);

  const triggerFetchSuggestions = async (search = '') => {
    findBaseToken().vm.$emit('fetch-suggestions', search);
    await waitForPromises();
  };

  const createComponent = ({ props = {}, handler = queryHandler } = {}) => {
    const mockApollo = createMockApollo([[searchProjectTopics, handler]]);

    wrapper = shallowMountExtended(TopicToken, {
      apolloProvider: mockApollo,
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  beforeEach(() => {
    queryHandler = jest.fn().mockResolvedValue(mockTopicsResponse);
  });

  it('renders the base token with correct props', () => {
    createComponent();

    expect(findBaseToken().props()).toMatchObject({
      active: false,
      config: defaultProps.config,
      value: defaultProps.value,
      suggestions: [],
      suggestionsLoading: false,
    });
  });

  describe('fetching topics', () => {
    it('fetches topics when base token emits fetch-suggestions', async () => {
      createComponent();

      await triggerFetchSuggestions('ruby');

      expect(queryHandler).toHaveBeenCalledWith({ search: 'ruby' });
    });

    it('passes fetched topics as suggestions to base token', async () => {
      createComponent();

      await triggerFetchSuggestions();

      expect(findBaseToken().props('suggestions')).toEqual([
        { value: 'ruby', text: 'Ruby' },
        { value: 'ci-cd', text: 'CI/CD' },
        { value: 'devops', text: 'DevOps' },
      ]);
    });

    it('sets suggestionsLoading while fetching', async () => {
      createComponent();

      expect(findBaseToken().props('suggestionsLoading')).toBe(false);

      findBaseToken().vm.$emit('fetch-suggestions', '');
      await nextTick();

      expect(findBaseToken().props('suggestionsLoading')).toBe(true);

      await waitForPromises();
      expect(findBaseToken().props('suggestionsLoading')).toBe(false);
    });

    it('passes empty suggestions for empty response', async () => {
      const emptyHandler = jest.fn().mockResolvedValue({
        data: { topics: { nodes: [] } },
      });
      createComponent({ handler: emptyHandler });

      await triggerFetchSuggestions();

      expect(findBaseToken().props('suggestions')).toEqual([]);
    });

    it('shows an alert on error', async () => {
      const errorHandler = jest.fn().mockRejectedValue(new Error('GraphQL error'));
      createComponent({ handler: errorHandler });

      await triggerFetchSuggestions();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'There was an error fetching topics.',
      });
    });
  });
});
