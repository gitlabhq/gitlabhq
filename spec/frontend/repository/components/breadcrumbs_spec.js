import { shallowMount, RouterLinkStub } from '@vue/test-utils';
import Breadcrumbs from '~/repository/components/breadcrumbs.vue';

let vm;

function factory(currentPath) {
  vm = shallowMount(Breadcrumbs, {
    propsData: {
      currentPath,
    },
    stubs: {
      RouterLink: RouterLinkStub,
    },
  });
}

describe('Repository breadcrumbs component', () => {
  afterEach(() => {
    vm.destroy();
  });

  it.each`
    path                        | linkCount
    ${'/'}                      | ${1}
    ${'app'}                    | ${2}
    ${'app/assets'}             | ${3}
    ${'app/assets/javascripts'} | ${4}
  `('renders $linkCount links for path $path', ({ path, linkCount }) => {
    factory(path);

    expect(vm.findAll(RouterLinkStub).length).toEqual(linkCount);
  });

  it('renders last link as active', () => {
    factory('app/assets');

    expect(
      vm
        .findAll(RouterLinkStub)
        .at(2)
        .attributes('aria-current'),
    ).toEqual('page');
  });
});
