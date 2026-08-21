import { GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { handleLocationHash, isLoggedIn } from '~/lib/utils/common_utils';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import waitForPromises from 'helpers/wait_for_promises';
import Preview from '~/repository/components/preview/index.vue';
import projectPathQuery from '~/repository/queries/project_path.query.graphql';
import refQuery from '~/repository/queries/ref.query.graphql';
import blobEditQuery from '~/repository/queries/blob_edit.query.graphql';

const PROPS_DATA = {
  blob: {
    webPath: 'http://test.com',
    name: 'README.md',
    path: 'README.md',
  },
};

const MOCK_README_DATA = {
  __typename: 'ReadmeFile',
  html: '<div class="blob">test</div>',
};

const blobEditResponse = ({ canModifyBlob = true, nodes } = {}) => ({
  data: {
    project: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      repository: {
        __typename: 'Repository',
        blobs: {
          __typename: 'RepositoryBlobConnection',
          nodes: nodes ?? [
            {
              __typename: 'RepositoryBlob',
              id: 'gid://gitlab/Blob/1',
              canModifyBlob,
              editBlobPath: '/group/project/-/edit/main/README.md',
            },
          ],
        },
      },
    },
  },
});

jest.mock('~/lib/utils/common_utils');
jest.mock('~/lib/logger');
jest.mock('~/sentry/sentry_browser_wrapper');

Vue.use(VueApollo);

let wrapper;
let mockApollo;
let mockReadmeData;

const mockResolvers = {
  Query: {
    readme: () => mockReadmeData(),
  },
};

const findEditButton = () => wrapper.findByTestId('edit-readme-button');

function createComponent(blobEditHandler = jest.fn().mockResolvedValue(blobEditResponse())) {
  mockApollo = createMockApollo([[blobEditQuery, blobEditHandler]], mockResolvers);

  mockApollo.clients.defaultClient.cache.writeQuery({
    query: projectPathQuery,
    data: { projectPath: 'group/project' },
  });

  mockApollo.clients.defaultClient.cache.writeQuery({
    query: refQuery,
    data: { ref: 'main', escapedRef: 'main' },
  });

  return shallowMountExtended(Preview, {
    propsData: PROPS_DATA,
    apolloProvider: mockApollo,
  });
}

describe('Repository file preview component', () => {
  beforeEach(() => {
    isLoggedIn.mockReturnValue(true);
    mockReadmeData = jest.fn().mockResolvedValue(MOCK_README_DATA);
  });

  it('handles hash after render', async () => {
    wrapper = createComponent();

    await waitForPromises();

    expect(handleLocationHash).toHaveBeenCalled();
  });

  it('renders loading icon', () => {
    wrapper = createComponent();

    expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
  });

  describe('edit file button', () => {
    describe('when the user can modify the blob', () => {
      beforeEach(() => {
        wrapper = createComponent();
        return waitForPromises();
      });

      it('renders the edit button', () => {
        expect(findEditButton().exists()).toBe(true);
        expect(findEditButton().attributes('href')).toBe('/group/project/-/edit/main/README.md');
        expect(findEditButton().attributes('aria-label')).toBe('Edit file README.md');
        expect(findEditButton().text()).toBe('Edit file');
      });
    });

    describe('when the user cannot modify the blob', () => {
      beforeEach(() => {
        wrapper = createComponent(
          jest.fn().mockResolvedValue(blobEditResponse({ canModifyBlob: false })),
        );
        return waitForPromises();
      });

      it('does not render the edit button', () => {
        expect(findEditButton().exists()).toBe(false);
      });
    });

    describe('when the blob is not found', () => {
      beforeEach(() => {
        wrapper = createComponent(jest.fn().mockResolvedValue(blobEditResponse({ nodes: [] })));
        return waitForPromises();
      });

      it('does not render the edit button', () => {
        expect(findEditButton().exists()).toBe(false);
      });
    });

    describe('when the user is not logged in', () => {
      let blobEditHandler;

      beforeEach(() => {
        isLoggedIn.mockReturnValue(false);
        blobEditHandler = jest.fn().mockResolvedValue(blobEditResponse());
        wrapper = createComponent(blobEditHandler);
        return waitForPromises();
      });

      it('does not fire the query and does not render the edit button', () => {
        expect(blobEditHandler).not.toHaveBeenCalled();
        expect(findEditButton().exists()).toBe(false);
      });
    });

    describe('when the query fails', () => {
      const queryError = new Error('GraphQL error');

      beforeEach(() => {
        wrapper = createComponent(jest.fn().mockRejectedValue(queryError));
        return waitForPromises();
      });

      it('reports the error and does not render the edit button', () => {
        expect(captureException).toHaveBeenCalledWith(queryError);
        expect(findEditButton().exists()).toBe(false);
      });
    });
  });
});
