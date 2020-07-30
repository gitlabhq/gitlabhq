import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import { handleLocationHash } from '~/lib/utils/common_utils';
import Preview from '~/repository/components/preview/index.vue';

jest.mock('~/lib/utils/common_utils');

let vm;
let $apollo;

function factory(blob) {
  $apollo = {
    query: jest.fn().mockReturnValue(Promise.resolve({})),
  };

  vm = shallowMount(Preview, {
    propsData: {
      blob,
    },
    mocks: {
      $apollo,
    },
  });
}

describe('Repository file preview component', () => {
  afterEach(() => {
    vm.destroy();
  });

  it('renders file HTML', () => {
    factory({
      webPath: 'http://test.com',
      name: 'README.md',
    });

    vm.setData({ readme: { html: '<div class="blob">test</div>' } });

    return vm.vm.$nextTick(() => {
      expect(vm.element).toMatchSnapshot();
    });
  });

  it('handles hash after render', () => {
    factory({
      webPath: 'http://test.com',
      name: 'README.md',
    });

    vm.setData({ readme: { html: '<div class="blob">test</div>' } });

    return vm.vm
      .$nextTick()
      .then(vm.vm.$nextTick())
      .then(() => {
        expect(handleLocationHash).toHaveBeenCalled();
      });
  });

  it('renders loading icon', () => {
    factory({
      webPath: 'http://test.com',
      name: 'README.md',
    });

    vm.setData({ loading: 1 });

    return vm.vm.$nextTick(() => {
      expect(vm.find(GlLoadingIcon).exists()).toBe(true);
    });
  });
});
