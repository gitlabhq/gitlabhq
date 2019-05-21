import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import Table from '~/repository/components/table/index.vue';

let vm;

function factory(path, loading = false) {
  vm = shallowMount(Table, {
    propsData: {
      path,
    },
    mocks: {
      $apollo: {
        queries: {
          files: { loading },
        },
      },
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

  it('renders loading icon', () => {
    factory('/', true);

    expect(vm.find(GlLoadingIcon).exists()).toBe(true);
  });
});
