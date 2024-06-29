import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import FilePreview from '~/repository/components/preview/index.vue';
import FileTable from '~/repository/components/table/index.vue';
import TreeContent from 'jh_else_ce/repository/components/tree_content.vue';
import { TREE_PAGE_LIMIT, i18n } from '~/repository/constants';
import { loadCommits, isRequested, resetRequestedCommits } from '~/repository/commits_service';
import createApolloProvider from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import paginatedTreeQuery from 'shared_queries/repository/paginated_tree.query.graphql';
import projectPathQuery from '~/repository/queries/project_path.query.graphql';

import { createAlert } from '~/alert';
import { graphQLErrors, paginatedTreeResponseFactory } from '../mock_data';

jest.mock('~/repository/commits_service', () => ({
  loadCommits: jest.fn(() => Promise.resolve()),
  isRequested: jest.fn(),
  resetRequestedCommits: jest.fn(),
}));
jest.mock('~/alert');

describe('Repository table component', () => {
  Vue.use(VueApollo);
  let wrapper;

  const paginatedTreeResponseWithMoreThanLimit = jest
    .fn()
    .mockResolvedValue(paginatedTreeResponseFactory({ numberOfBlobs: TREE_PAGE_LIMIT + 2 }));
  const paginatedTreeQueryResponseHandler = jest
    .fn()
    .mockResolvedValue(paginatedTreeResponseFactory());
  const findFileTable = () => wrapper.findComponent(FileTable);

  const createComponent = ({
    path = '/',
    responseHandler = paginatedTreeQueryResponseHandler,
  } = {}) => {
    const apolloProvider = createApolloProvider([[paginatedTreeQuery, responseHandler]]);

    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: projectPathQuery,
      data: {
        projectPath: path,
      },
    });

    wrapper = shallowMount(TreeContent, {
      apolloProvider,
      propsData: {
        path,
      },
      provide: { refType: 'heads' },
    });
  };

  it('renders file preview when the response has README.md', async () => {
    const paginatedTreeResponseWithReadMe = jest
      .fn()
      .mockResolvedValue(paginatedTreeResponseFactory({ numberOfBlobs: 1, blobHasReadme: true }));
    createComponent({ responseHandler: paginatedTreeResponseWithReadMe });
    await nextTick();

    await waitForPromises();
    expect(wrapper.findComponent(FilePreview).exists()).toBe(true);
  });

  it('calls tree response handler and  resetRequestedCommits when mounted', async () => {
    createComponent();

    await nextTick();

    expect(paginatedTreeQueryResponseHandler).toHaveBeenCalled();
    expect(resetRequestedCommits).toHaveBeenCalled();
  });

  describe('normalizeData', () => {
    it('normalizes edge nodes', async () => {
      createComponent();

      await nextTick();
      await waitForPromises();

      const [paginatedTreeNode] =
        paginatedTreeResponseFactory().data.project.repository.paginatedTree.nodes;

      const {
        blobs: { nodes: blobs },
        trees: { nodes: trees },
        submodules: { nodes: submodules },
      } = paginatedTreeNode;

      expect(findFileTable().props('entries')).toEqual({
        blobs,
        trees,
        submodules,
      });
    });
  });

  describe('when there is next page', () => {
    it('make sure it has the correct props to filetable', async () => {
      createComponent({ responseHandler: paginatedTreeResponseWithMoreThanLimit });

      await nextTick();
      await waitForPromises();

      expect(findFileTable().props('hasMore')).toBe(true);
    });
  });

  describe('FileTable', () => {
    describe('when "showMore" event is emitted', () => {
      beforeEach(async () => {
        createComponent();
        await nextTick();
        await waitForPromises();
      });

      it('changes hasShowMore to false', async () => {
        findFileTable().vm.$emit('showMore');

        await nextTick();

        expect(findFileTable().props('hasMore')).toBe(false);
      });

      it('triggers the tree responseHandler', () => {
        findFileTable().vm.$emit('showMore');

        expect(paginatedTreeQueryResponseHandler).toHaveBeenCalled();
      });
    });

    describe('"hasMore" props is correctly computed with the limit to 1000 per page', () => {
      it.each`
        totalBlobs | limitReached
        ${500}     | ${false}
        ${900}     | ${false}
        ${1000}    | ${true}
        ${1002}    | ${true}
        ${2000}    | ${true}
      `(
        'is `$limitReached` when the number of entries is `$totalBlobs`',
        async ({ totalBlobs, limitReached }) => {
          const paginatedTreeResponseHandler = jest
            .fn()
            .mockResolvedValue(paginatedTreeResponseFactory({ numberOfBlobs: totalBlobs }));
          createComponent({ responseHandler: paginatedTreeResponseHandler });

          await nextTick();
          await waitForPromises();

          expect(findFileTable().props('hasMore')).toBe(limitReached);
        },
      );
    });
  });

  describe('commit data', () => {
    const path = '';

    it('loads commit data for the nearest page', () => {
      createComponent({ path });
      findFileTable().vm.$emit('row-appear', 49);
      findFileTable().vm.$emit('row-appear', 15);

      expect(isRequested).toHaveBeenCalledWith(49);
      expect(isRequested).toHaveBeenCalledWith(15);

      expect(loadCommits.mock.calls).toEqual([
        ['', path, '', 25, 'heads'],
        ['', path, '', 0, 'heads'],
      ]);
    });
  });

  describe('error handling', () => {
    const gitalyError = { graphQLErrors };
    it.each`
      error          | message
      ${gitalyError} | ${i18n.gitalyError}
      ${'Error'}     | ${i18n.generalError}
    `(
      `when the graphql error is "$error" shows the message "$message"`,
      async ({ error, message }) => {
        createComponent({ path: '/', responseHandler: jest.fn().mockRejectedValue(error) });
        await waitForPromises();
        expect(createAlert).toHaveBeenCalledWith({ message, captureError: true });
      },
    );
  });
});
