import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlSkeletonLoader, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Table from '~/repository/components/table/index.vue';
import TableRow from '~/repository/components/table/row.vue';
import refQuery from '~/repository/queries/ref.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';

let wrapper;

const createMockApolloProvider = (ref) => {
  Vue.use(VueApollo);
  const apolloProver = createMockApollo([]);
  apolloProver.clients.defaultClient.cache.writeQuery({
    query: refQuery,
    data: { ref, escapedRef: ref },
  });

  return apolloProver;
};

const MOCK_BLOBS = [
  {
    id: '123abc',
    sha: '123abc',
    flatPath: 'blob',
    name: 'blob.md',
    type: 'blob',
    webPath: '/blob',
  },
  {
    id: '124abc',
    sha: '124abc',
    flatPath: 'blob2',
    name: 'blob2.md',
    type: 'blob',
    webUrl: 'http://test.com',
  },
  {
    id: '125abc',
    sha: '125abc',
    flatPath: 'blob3',
    name: 'blob3.md',
    type: 'blob',
    webUrl: 'http://test.com',
    mode: '120000',
  },
];

const MOCK_COMMITS = [
  {
    fileName: 'blob.md',
    filePath: 'test_dir/blob.md',
    type: 'blob',
    commit: {
      message: 'Updated blob.md',
    },
  },
  {
    fileName: 'blob2.md',
    filePath: 'test_dir/blob2.md',
    type: 'blob',
    commit: {
      message: 'Updated blob2.md',
    },
  },
  {
    fileName: 'blob3.md',
    filePath: 'test_dir/blob3.md',
    type: 'blob',
    commit: {
      message: 'Updated blob3.md',
    },
  },
  {
    fileName: 'root_blob.md',
    filePath: '/root_blob.md',
    type: 'blob',
    commit: {
      message: 'Updated root_blob.md',
    },
  },
];

function factory({
  path,
  isLoading = false,
  hasMore = true,
  entries = {},
  commits = [],
  ref = 'main',
}) {
  wrapper = shallowMount(Table, {
    propsData: {
      path,
      isLoading,
      entries,
      hasMore,
      commits,
    },
    apolloProvider: createMockApolloProvider(ref),
  });
}

const findTableRows = () => wrapper.findAllComponents(TableRow);

describe('Repository table component', () => {
  it.each`
    path            | ref
    ${'/'}          | ${'main'}
    ${'app/assets'} | ${'main'}
    ${'/'}          | ${'test'}
  `('renders table caption for $ref in $path', async ({ path, ref }) => {
    factory({ path, ref });

    await nextTick();
    expect(wrapper.find('.table').attributes('aria-label')).toEqual(
      `Files, directories, and submodules in the path ${path} for commit reference ${ref}`,
    );
  });

  it('shows loading icon', () => {
    factory({ path: '/', isLoading: true });

    expect(wrapper.findComponent(GlSkeletonLoader).exists()).toBe(true);
  });

  it('renders table rows', () => {
    factory({
      path: 'test_dir',
      entries: {
        blobs: MOCK_BLOBS,
      },
      commits: MOCK_COMMITS,
    });

    const rows = findTableRows();

    expect(rows.length).toEqual(3);
    expect(rows.at(2).attributes().mode).toEqual('120000');
    expect(rows.at(2).props().rowNumber).toBe(2);
    expect(rows.at(2).props().commitInfo).toEqual(MOCK_COMMITS[2]);
  });

  it('renders correct commit info for blobs in the root', () => {
    factory({
      path: '/',
      entries: {
        blobs: [
          {
            id: '126abc',
            sha: '126abc',
            flatPath: 'root_blob.md',
            name: 'root_blob.md',
            type: 'blob',
            webUrl: 'http://test.com',
            mode: '120000',
          },
        ],
      },
      commits: MOCK_COMMITS,
    });

    expect(findTableRows().at(0).props().commitInfo).toEqual(MOCK_COMMITS[3]);
  });

  describe('Show more button', () => {
    const showMoreButton = () => wrapper.findComponent(GlButton);

    it.each`
      hasMore  | expectButtonToExist
      ${true}  | ${true}
      ${false} | ${false}
    `('renders correctly', ({ hasMore, expectButtonToExist }) => {
      factory({ path: '/', hasMore });
      expect(showMoreButton().exists()).toBe(expectButtonToExist);
    });

    it('when is clicked, emits showMore event', async () => {
      factory({ path: '/' });

      showMoreButton().vm.$emit('click');

      await nextTick();

      expect(wrapper.emitted('showMore')).toHaveLength(1);
    });
  });
});
