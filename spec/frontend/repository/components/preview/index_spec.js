import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import Preview from '~/repository/components/preview/index.vue';

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
      webUrl: 'http://test.com',
      name: 'README.md',
    });

    vm.setData({ readme: { html: '<div class="blob">test</div>' } });

    return vm.vm.$nextTick(() => {
      expect(vm.element).toMatchSnapshot();
    });
  });

  it('renders loading icon', () => {
    factory({
      webUrl: 'http://test.com',
      name: 'README.md',
    });

    vm.setData({ loading: 1 });

    return vm.vm.$nextTick(() => {
      expect(vm.find(GlLoadingIcon).exists()).toBe(true);
    });
  });
});
