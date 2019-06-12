import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import Table from '~/repository/components/table/index.vue';

let vm;
let $apollo;

function factory(path, data = () => ({})) {
  $apollo = {
    query: jest.fn().mockReturnValue(Promise.resolve({ data: data() })),
  };

  vm = shallowMount(Table, {
    propsData: {
      path,
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
    factory(path);

    vm.setData({ ref });

    expect(vm.find('caption').text()).toEqual(
      `Files, directories, and submodules in the path ${path} for commit reference ${ref}`,
    );
  });

  it('shows loading icon', () => {
    factory('/');

    vm.setData({ isLoadingFiles: true });

    expect(vm.find(GlLoadingIcon).isVisible()).toBe(true);
  });

  describe('normalizeData', () => {
    it('normalizes edge nodes', () => {
      const output = vm.vm.normalizeData('blobs', [{ node: '1' }, { node: '2' }]);

      expect(output).toEqual(['1', '2']);
    });
  });

  describe('hasNextPage', () => {
    it('returns undefined when hasNextPage is false', () => {
      const output = vm.vm.hasNextPage({
        trees: { pageInfo: { hasNextPage: false } },
        submodules: { pageInfo: { hasNextPage: false } },
        blobs: { pageInfo: { hasNextPage: false } },
      });

      expect(output).toBe(undefined);
    });

    it('returns pageInfo object when hasNextPage is true', () => {
      const output = vm.vm.hasNextPage({
        trees: { pageInfo: { hasNextPage: false } },
        submodules: { pageInfo: { hasNextPage: false } },
        blobs: { pageInfo: { hasNextPage: true, nextCursor: 'test' } },
      });

      expect(output).toEqual({ hasNextPage: true, nextCursor: 'test' });
    });
  });
});
