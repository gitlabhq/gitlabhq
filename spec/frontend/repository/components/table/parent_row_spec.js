import { shallowMount, RouterLinkStub } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import ParentRow from '~/repository/components/table/parent_row.vue';

let vm;
let $router;

function factory(path, loadingPath) {
  $router = {
    push: jest.fn(),
  };

  vm = shallowMount(ParentRow, {
    propsData: {
      commitRef: 'master',
      path,
      loadingPath,
    },
    stubs: {
      RouterLink: RouterLinkStub,
    },
    mocks: {
      $router,
    },
  });
}

describe('Repository parent row component', () => {
  afterEach(() => {
    vm.destroy();
  });

  it.each`
    path            | to
    ${'app'}        | ${'/tree/master/'}
    ${'app/assets'} | ${'/tree/master/app'}
  `('renders link in $path to $to', ({ path, to }) => {
    factory(path);

    expect(vm.find(RouterLinkStub).props().to).toEqual({
      path: to,
    });
  });

  it('pushes new router when clicking row', () => {
    factory('app/assets');

    vm.find('td').trigger('click');

    expect($router.push).toHaveBeenCalledWith({
      path: '/tree/master/app',
    });
  });

  // We test that it does not get called when clicking any internal
  // links as this was causing multipe routes to get pushed
  it('does not trigger router.push when clicking link', () => {
    factory('app/assets');

    vm.find('a').trigger('click');

    expect($router.push).not.toHaveBeenCalledWith({
      path: '/tree/master/app',
    });
  });

  it('renders loading icon when loading parent', () => {
    factory('app/assets', 'app');

    expect(vm.find(GlLoadingIcon).exists()).toBe(true);
  });
});
