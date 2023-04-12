import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlLoadingIcon } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import LastCommit from '~/repository/components/last_commit.vue';
import SignatureBadge from '~/commit/components/signature_badge.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import eventHub from '~/repository/event_hub';
import pathLastCommitQuery from 'shared_queries/repository/path_last_commit.query.graphql';
import { FORK_UPDATED_EVENT } from '~/repository/constants';
import { refMock } from '../mock_data';

let wrapper;
let mockResolver;

const findPipeline = () => wrapper.find('.js-commit-pipeline');
const findTextExpander = () => wrapper.find('.text-expander');
const findUserLink = () => wrapper.find('.js-user-link');
const findUserAvatarLink = () => wrapper.findComponent(UserAvatarLink);
const findLastCommitLabel = () => wrapper.findByTestId('last-commit-id-label');
const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
const findCommitRowDescription = () => wrapper.find('.commit-row-description');
const findStatusBox = () => wrapper.findComponent(SignatureBadge);
const findItemTitle = () => wrapper.find('.item-title');

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

const defaultAuthor = {
  __typename: 'UserCore',
  id: 'gid://gitlab/User/1',
  name: 'Test',
  avatarUrl: 'https://test.com',
  webPath: '/test',
};

const defaultMessage = 'Commit title';

const createCommitData = ({
  pipelineEdges = defaultPipelineEdges,
  author = defaultAuthor,
  descriptionHtml = '',
  signature = null,
  message = defaultMessage,
}) => {
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
                  descriptionHtml,
                  message,
                  webPath: '/commit/123',
                  authoredDate: '2019-01-01',
                  authorName: 'Test',
                  authorGravatar: 'https://test.com',
                  author,
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

  mockResolver = jest.fn().mockResolvedValue(createCommitData(data));

  wrapper = shallowMountExtended(LastCommit, {
    apolloProvider: createMockApollo([[pathLastCommitQuery, mockResolver]]),
    propsData: { currentPath },
    mixins: [{ data: () => ({ ref: refMock }) }],
    stubs: {
      SignatureBadge,
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

  it('hides author component when author does not exist', async () => {
    createComponent({ author: null });
    await waitForPromises();

    expect(findUserLink().exists()).toBe(false);
    expect(findUserAvatarLink().exists()).toBe(false);
  });

  it('does not render description expander when description is null', async () => {
    createComponent();
    await waitForPromises();

    expect(findTextExpander().exists()).toBe(false);
    expect(findCommitRowDescription().exists()).toBe(false);
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

  describe('when the description is present', () => {
    beforeEach(async () => {
      createComponent({ descriptionHtml: '&#x000A;Update ADOPTERS.md' });
      await waitForPromises();
    });

    it('strips the first newline of the description', () => {
      expect(findCommitRowDescription().html()).toBe(
        '<pre class="commit-row-description gl-mb-3 gl-white-space-pre-line">Update ADOPTERS.md</pre>',
      );
    });

    it('expands commit description when clicking expander', async () => {
      expect(findCommitRowDescription().classes('d-block')).toBe(false);
      expect(findTextExpander().classes('open')).toBe(false);
      expect(findTextExpander().props('selected')).toBe(false);

      findTextExpander().vm.$emit('click');
      await nextTick();

      expect(findCommitRowDescription().classes('d-block')).toBe(true);
      expect(findTextExpander().classes('open')).toBe(true);
      expect(findTextExpander().props('selected')).toBe(true);
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

  it('sets correct CSS class if the commit message is empty', async () => {
    createComponent({ message: '' });
    await waitForPromises();

    expect(findItemTitle().classes()).toContain('font-italic');
  });
});
