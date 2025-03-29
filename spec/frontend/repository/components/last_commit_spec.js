import Vue from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LastCommit from '~/repository/components/last_commit.vue';
import CommitInfo from '~/repository/components/commit_info.vue';
import SignatureBadge from '~/commit/components/signature_badge.vue';
import PipelineCiStatus from '~/vue_shared/components/ci_status/pipeline_ci_status.vue';
import eventHub from '~/repository/event_hub';
import pathLastCommitQuery from 'shared_queries/repository/path_last_commit.query.graphql';
import projectPathQuery from '~/repository/queries/project_path.query.graphql';
import { FORK_UPDATED_EVENT } from '~/repository/constants';

let wrapper;
let commitData;
let mockResolver;

const findLastCommitLabel = () => wrapper.findByTestId('last-commit-id-label');
const findHistoryButton = () => wrapper.findByTestId('last-commit-history');
const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
const findStatusBox = () => wrapper.findComponent(SignatureBadge);
const findCommitInfo = () => wrapper.findComponent(CommitInfo);
const findPipeline = () => wrapper.findComponent(PipelineCiStatus);

const defaultPipelineEdges = [
  {
    __typename: 'PipelineEdge',
    node: {
      __typename: 'Pipeline',
      id: 'gid://gitlab/Ci::Pipeline/167',
    },
  },
];

const createCommitData = ({ pipelineEdges = defaultPipelineEdges, signature = null }) => {
  return {
    data: {
      project: {
        __typename: 'Project',
        id: 'gid://gitlab/Project/6',
        repository: {
          __typename: 'Repository',
          paginatedTree: {
            __typename: 'TreeConnection',
            nodes: [
              {
                __typename: 'Tree',
                lastCommit: {
                  __typename: 'Commit',
                  id: 'gid://gitlab/CommitPresenter/123456789',
                  sha: '123456789',
                  title: 'Commit title',
                  titleHtml: 'Commit title',
                  descriptionHtml: '',
                  message: '',
                  webPath: '/commit/123',
                  authoredDate: '2019-01-01',
                  authorName: 'Test',
                  authorGravatar: 'https://test.com',
                  author: {
                    __typename: 'UserCore',
                    id: 'gid://gitlab/User/1',
                    name: 'Test',
                    avatarUrl: 'https://test.com',
                    webPath: '/test',
                  },
                  signature,
                  pipelines: {
                    __typename: 'PipelineConnection',
                    edges: pipelineEdges,
                  },
                },
              },
            ],
          },
        },
      },
    },
  };
};

const createComponent = (data = {}) => {
  Vue.use(VueApollo);

  const currentPath = 'path';

  commitData = createCommitData(data);
  mockResolver = jest.fn().mockResolvedValue(commitData);

  const apolloProvider = createMockApollo([[pathLastCommitQuery, mockResolver]]);

  apolloProvider.clients.defaultClient.cache.writeQuery({
    query: projectPathQuery,
    data: {
      projectPath: 'gitlab-org/gitlab-foss',
    },
  });

  wrapper = shallowMountExtended(LastCommit, {
    apolloProvider,
    propsData: { currentPath, historyUrl: '/history' },
    provide: {
      glFeatures: {
        ciPipelineStatusRealtime: false,
      },
    },
  });
};

afterEach(() => {
  mockResolver = null;
});

describe('Repository last commit component', () => {
  it.each`
    loading  | label
    ${true}  | ${'shows'}
    ${false} | ${'hides'}
  `('$label when loading icon is $loading', async ({ loading }) => {
    createComponent();

    if (!loading) {
      await waitForPromises();
    }

    expect(findLoadingIcon().exists()).toBe(loading);
  });

  it('renders a CommitInfo component', async () => {
    createComponent();

    await waitForPromises();

    const commit = { ...commitData.project?.repository.paginatedTree.nodes[0].lastCommit };

    expect(findCommitInfo().props().commit).toMatchObject(commit);
  });

  it('renders commit widget', async () => {
    createComponent();

    await waitForPromises();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders short commit ID', async () => {
    createComponent();

    await waitForPromises();

    expect(findLastCommitLabel().text()).toBe('12345678');
  });

  it('renders History button with correct href', async () => {
    createComponent();

    await waitForPromises();

    expect(findHistoryButton().exists()).toBe(true);
    expect(findHistoryButton().attributes('href')).toContain('/history');
  });

  it('hides pipeline components when pipeline does not exist', async () => {
    createComponent({ pipelineEdges: [] });

    await waitForPromises();

    expect(findPipeline().exists()).toBe(false);
  });

  it('renders pipeline components when pipeline exists', async () => {
    createComponent();

    await waitForPromises();

    expect(findPipeline().exists()).toBe(true);
  });

  describe('created', () => {
    it('binds `epicsListScrolled` event listener via eventHub', () => {
      jest.spyOn(eventHub, '$on').mockImplementation(() => {});

      createComponent();

      expect(eventHub.$on).toHaveBeenCalledWith(FORK_UPDATED_EVENT, expect.any(Function));
    });
  });

  describe('beforeDestroy', () => {
    it('unbinds `epicsListScrolled` event listener via eventHub', () => {
      jest.spyOn(eventHub, '$off').mockImplementation(() => {});

      createComponent();

      wrapper.destroy();

      expect(eventHub.$off).toHaveBeenCalledWith(FORK_UPDATED_EVENT, expect.any(Function));
    });
  });

  it('renders the signature HTML as returned by the backend', async () => {
    const signatureResponse = {
      __typename: 'GpgSignature',
      gpgKeyPrimaryKeyid: 'xxx',
      verificationStatus: 'VERIFIED',
    };

    createComponent({
      signature: {
        ...signatureResponse,
      },
    });

    await waitForPromises();

    expect(findStatusBox().props()).toMatchObject({ signature: signatureResponse });
  });
});
