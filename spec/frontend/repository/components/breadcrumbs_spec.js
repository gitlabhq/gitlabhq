import { shallowMount, RouterLinkStub } from '@vue/test-utils';
import { GlDropdown } from '@gitlab/ui';
import Breadcrumbs from '~/repository/components/breadcrumbs.vue';

let vm;

function factory(currentPath, extraProps = {}) {
  vm = shallowMount(Breadcrumbs, {
    propsData: {
      currentPath,
      ...extraProps,
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

  it('does not render add to tree dropdown when permissions are false', () => {
    factory('/', { canCollaborate: false });

    vm.setData({ userPermissions: { forkProject: false, createMergeRequestIn: false } });

    return vm.vm.$nextTick(() => {
      expect(vm.find(GlDropdown).exists()).toBe(false);
    });
  });

  it('renders add to tree dropdown when permissions are true', () => {
    factory('/', { canCollaborate: true });

    vm.setData({ userPermissions: { forkProject: true, createMergeRequestIn: true } });

    return vm.vm.$nextTick(() => {
      expect(vm.find(GlDropdown).exists()).toBe(true);
    });
  });
});
