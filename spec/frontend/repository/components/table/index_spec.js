import { shallowMount } from '@vue/test-utils';
import { GlSkeletonLoading } from '@gitlab/ui';
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
    webUrl: 'http://test.com',
  },
  {
    id: '124abc',
    sha: '124abc',
    flatPath: 'blob2',
    name: 'blob2.md',
    type: 'blob',
    webUrl: 'http://test.com',
  },
];

function factory({ path, isLoading = false, entries = {} }) {
  vm = shallowMount(Table, {
    propsData: {
      path,
      isLoading,
      entries,
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
    ${'/'}          | ${'master'}
    ${'app/assets'} | ${'master'}
    ${'/'}          | ${'test'}
  `('renders table caption for $ref in $path', ({ path, ref }) => {
    factory({ path });

    vm.setData({ ref });

    expect(vm.find('.table').attributes('aria-label')).toEqual(
      `Files, directories, and submodules in the path ${path} for commit reference ${ref}`,
    );
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

    expect(vm.find(TableRow).exists()).toBe(true);
    expect(vm.findAll(TableRow).length).toBe(2);
  });
});
