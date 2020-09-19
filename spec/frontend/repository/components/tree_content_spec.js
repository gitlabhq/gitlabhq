import { shallowMount } from '@vue/test-utils';
import TreeContent, { INITIAL_FETCH_COUNT } from '~/repository/components/tree_content.vue';
import FilePreview from '~/repository/components/preview/index.vue';
import FileTable from '~/repository/components/table/index.vue';

let vm;
let $apollo;

function factory(path, data = () => ({})) {
  $apollo = {
    query: jest.fn().mockReturnValue(Promise.resolve({ data: data() })),
  };

  vm = shallowMount(TreeContent, {
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

  it('renders file preview', async () => {
    factory('/');

    vm.setData({ entries: { blobs: [{ name: 'README.md' }] } });

    await vm.vm.$nextTick();

    expect(vm.find(FilePreview).exists()).toBe(true);
  });

  it('trigger fetchFiles when mounted', async () => {
    factory('/');

    jest.spyOn(vm.vm, 'fetchFiles').mockImplementation(() => {});

    await vm.vm.$nextTick();

    expect(vm.vm.fetchFiles).toHaveBeenCalled();
  });

  describe('normalizeData', () => {
    it('normalizes edge nodes', () => {
      factory('/');

      const output = vm.vm.normalizeData('blobs', [{ node: '1' }, { node: '2' }]);

      expect(output).toEqual(['1', '2']);
    });
  });

  describe('hasNextPage', () => {
    it('returns undefined when hasNextPage is false', () => {
      factory('/');

      const output = vm.vm.hasNextPage({
        trees: { pageInfo: { hasNextPage: false } },
        submodules: { pageInfo: { hasNextPage: false } },
        blobs: { pageInfo: { hasNextPage: false } },
      });

      expect(output).toBe(undefined);
    });

    it('returns pageInfo object when hasNextPage is true', () => {
      factory('/');

      const output = vm.vm.hasNextPage({
        trees: { pageInfo: { hasNextPage: false } },
        submodules: { pageInfo: { hasNextPage: false } },
        blobs: { pageInfo: { hasNextPage: true, nextCursor: 'test' } },
      });

      expect(output).toEqual({ hasNextPage: true, nextCursor: 'test' });
    });
  });

  describe('FileTable showMore', () => {
    describe('when is present', () => {
      const fileTable = () => vm.find(FileTable);

      beforeEach(async () => {
        factory('/');
      });

      it('is changes hasShowMore to false when "showMore" event is emitted', async () => {
        fileTable().vm.$emit('showMore');

        await vm.vm.$nextTick();

        expect(vm.vm.hasShowMore).toBe(false);
      });

      it('changes clickedShowMore when "showMore" event is emitted', async () => {
        fileTable().vm.$emit('showMore');

        await vm.vm.$nextTick();

        expect(vm.vm.clickedShowMore).toBe(true);
      });

      it('triggers fetchFiles when "showMore" event is emitted', () => {
        jest.spyOn(vm.vm, 'fetchFiles');

        fileTable().vm.$emit('showMore');

        expect(vm.vm.fetchFiles).toHaveBeenCalled();
      });
    });

    it('is not rendered if less than 1000 files', async () => {
      factory('/');

      vm.setData({ fetchCounter: 5, clickedShowMore: false });

      await vm.vm.$nextTick();

      expect(vm.vm.hasShowMore).toBe(false);
    });

    it('has limit of 1000 files on initial load', () => {
      factory('/');

      expect(INITIAL_FETCH_COUNT * vm.vm.pageSize).toBe(1000);
    });
  });
});
