import { GlDeprecatedSkeletonLoading as GlSkeletonLoading, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Table from '~/repository/components/table/index.vue';
import TableRow from '~/repository/components/table/row.vue';

let vm;
let $apollo;

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

function factory({ path, isLoading = false, hasMore = true, entries = {} }) {
  vm = shallowMount(Table, {
    propsData: {
      path,
      isLoading,
      entries,
      hasMore,
    },
    mocks: {
      $apollo,
    },
  });
}

describe('Repository table component', () => {
  afterEach(() => {
    vm.destroy();
  });

  it.each`
    path            | ref
    ${'/'}          | ${'main'}
    ${'app/assets'} | ${'main'}
    ${'/'}          | ${'test'}
  `('renders table caption for $ref in $path', ({ path, ref }) => {
    factory({ path });

    vm.setData({ ref });

    return vm.vm.$nextTick(() => {
      expect(vm.find('.table').attributes('aria-label')).toEqual(
        `Files, directories, and submodules in the path ${path} for commit reference ${ref}`,
      );
    });
  });

  it('shows loading icon', () => {
    factory({ path: '/', isLoading: true });

    expect(vm.find(GlSkeletonLoading).exists()).toBe(true);
  });

  it('renders table rows', () => {
    factory({
      path: '/',
      entries: {
        blobs: MOCK_BLOBS,
      },
    });

    const rows = vm.findAll(TableRow);

    expect(rows.length).toEqual(3);
    expect(rows.at(2).attributes().mode).toEqual('120000');
  });

  describe('Show more button', () => {
    const showMoreButton = () => vm.find(GlButton);

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

      await vm.vm.$nextTick();

      expect(vm.emitted('showMore')).toHaveLength(1);
    });
  });
});
