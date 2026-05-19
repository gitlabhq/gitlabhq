import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { stubPerformanceWebAPI } from 'helpers/performance';
import GetSnippetQuery from 'shared_queries/snippet/snippet.query.graphql';
import { getSnippetMixin } from '~/snippets/mixins/snippets';
import { createGQLSnippetsQueryResponse, createGQLSnippet } from '../test_utils';

Vue.use(VueApollo);

const TEST_SNIPPET_GID = 'gid://gitlab/PersonalSnippet/42';

const createQueryResponse = () => createGQLSnippetsQueryResponse([createGQLSnippet()]);

describe('getSnippetMixin', () => {
  let querySpy;

  const dummyComponent = {
    mixins: [getSnippetMixin],
    template: '<div></div>',
  };

  const createComponent = (propsData = {}) => {
    querySpy = jest.fn().mockResolvedValue(createQueryResponse());

    const apolloProvider = createMockApollo([[GetSnippetQuery, querySpy]]);

    shallowMount(dummyComponent, {
      apolloProvider,
      propsData: {
        snippetGid: TEST_SNIPPET_GID,
        ...propsData,
      },
    });
  };

  beforeEach(() => {
    stubPerformanceWebAPI();
  });

  describe('GetSnippetQuery variables', () => {
    it('includes projectId when projectId prop is provided', async () => {
      createComponent({ projectId: 'gid://gitlab/Project/7' });
      await waitForPromises();

      expect(querySpy).toHaveBeenCalledWith({
        ids: [TEST_SNIPPET_GID],
        projectId: 'gid://gitlab/Project/7',
      });
    });

    it('does not include projectId when projectId prop is not provided', async () => {
      createComponent();
      await waitForPromises();

      expect(querySpy).toHaveBeenCalledWith({
        ids: [TEST_SNIPPET_GID],
      });
    });
  });
});
