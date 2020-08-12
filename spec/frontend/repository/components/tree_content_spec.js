import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import TreeContent, { INITIAL_FETCH_COUNT } from '~/repository/components/tree_content.vue';
import FilePreview from '~/repository/components/preview/index.vue';

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

  describe('Show more button', () => {
    const showMoreButton = () => vm.find(GlButton);

    describe('when is present', () => {
      beforeEach(async () => {
        factory('/');

        vm.setData({ fetchCounter: 10, clickedShowMore: false });

        await vm.vm.$nextTick();
      });

      it('is not rendered once it is clicked', async () => {
        showMoreButton().vm.$emit('click');
        await vm.vm.$nextTick();

        expect(showMoreButton().exists()).toBe(false);
      });

      it('is rendered', async () => {
        expect(showMoreButton().exists()).toBe(true);
      });

      it('changes clickedShowMore when show more button is clicked', async () => {
        showMoreButton().vm.$emit('click');

        expect(vm.vm.clickedShowMore).toBe(true);
      });

      it('triggers fetchFiles when show more button is clicked', async () => {
        jest.spyOn(vm.vm, 'fetchFiles');

        showMoreButton().vm.$emit('click');

        expect(vm.vm.fetchFiles).toBeCalled();
      });
    });

    it('is not rendered if less than 1000 files', async () => {
      factory('/');

      vm.setData({ fetchCounter: 5, clickedShowMore: false });

      await vm.vm.$nextTick();

      expect(showMoreButton().exists()).toBe(false);
    });

    it('has limit of 1000 files on initial load', () => {
      factory('/');

      expect(INITIAL_FETCH_COUNT * vm.vm.pageSize).toBe(1000);
    });
  });
});
