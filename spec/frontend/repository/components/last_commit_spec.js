import Vue, { nextTick } from 'vue';
import { GlLoadingIcon } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LastCommit from '~/repository/components/last_commit.vue';
import CommitInfo from '~/repository/components/commit_info.vue';
import SignatureBadge from '~/commit/components/signature_badge.vue';
import eventHub from '~/repository/event_hub';
import pathLastCommitQuery from 'shared_queries/repository/path_last_commit.query.graphql';
import { FORK_UPDATED_EVENT } from '~/repository/constants';
import { refMock } from '../mock_data';

let wrapper;
let commitData;
let mockResolver;

const findPipeline = () => wrapper.find('.js-commit-pipeline');
const findLastCommitLabel = () => wrapper.findByTestId('last-commit-id-label');
const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
const findStatusBox = () => wrapper.findComponent(SignatureBadge);
const findCommitInfo = () => wrapper.findComponent(CommitInfo);
const findHistoryButton = () => wrapper.findByTestId('last-commit-history');

const defaultPipelineEdges = [
  {
    __typename: 'PipelineEdge',
    node: {
      __typename: 'Pipeline',
      id: 'gid://gitlab/Ci::Pipeline/167',
      detailedStatus: {
        __typename: 'DetailedStatus',
        id: 'id',
        detailsPath: 'https://test.com/pipeline',
        icon: 'status_running',
        tooltip: 'failed',
        text: 'failed',
        group: 'failed',
      },
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

const createComponent = async (data = {}) => {
  Vue.use(VueApollo);

  const currentPath = 'path';

  commitData = createCommitData(data);
  mockResolver = jest.fn().mockResolvedValue(commitData);

  wrapper = shallowMountExtended(LastCommit, {
    apolloProvider: createMockApollo([[pathLastCommitQuery, mockResolver]]),
    propsData: { currentPath, historyUrl: '/history' },
    mixins: [{ data: () => ({ ref: refMock }) }],
    stubs: {
      SignatureBadge,
    },
  });

  await waitForPromises();
  await nextTick();
};

beforeEach(() => createComponent());

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

  it('renders a CommitInfo component', () => {
    const commit = { ...commitData.project?.repository.paginatedTree.nodes[0].lastCommit };

    expect(findCommitInfo().props().commit).toMatchObject(commit);
  });

  it('renders commit widget', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders short commit ID', () => {
    expect(findLastCommitLabel().text()).toBe('12345678');
  });

  it('renders History button with correct href', () => {
    expect(findHistoryButton().exists()).toBe(true);
    expect(findHistoryButton().attributes('href')).toContain('/history');
  });

  it('hides pipeline components when pipeline does not exist', async () => {
    createComponent({ pipelineEdges: [] });
    await waitForPromises();

    expect(findPipeline().exists()).toBe(false);
  });

  it('renders pipeline components when pipeline exists', () => {
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
