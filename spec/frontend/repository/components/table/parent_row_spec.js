import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, RouterLinkStub } from '@vue/test-utils';
import ParentRow from '~/repository/components/table/parent_row.vue';

let vm;
let $router;

function factory(path, loadingPath) {
  $router = {
    push: jest.fn(),
  };

  vm = shallowMount(ParentRow, {
    propsData: {
      commitRef: 'main',
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
    path                        | to
    ${'app'}                    | ${'/-/tree/main/'}
    ${'app/assets'}             | ${'/-/tree/main/app'}
    ${'app/assets#/test'}       | ${'/-/tree/main/app/assets%23'}
    ${'app/assets#/test/world'} | ${'/-/tree/main/app/assets%23/test'}
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
      path: '/-/tree/main/app',
    });
  });

  // We test that it does not get called when clicking any internal
  // links as this was causing multipe routes to get pushed
  it('does not trigger router.push when clicking link', () => {
    factory('app/assets');

    vm.find('a').trigger('click');

    expect($router.push).not.toHaveBeenCalledWith({
      path: '/-/tree/main/app',
    });
  });

  it('renders loading icon when loading parent', () => {
    factory('app/assets', 'app');

    expect(vm.find(GlLoadingIcon).exists()).toBe(true);
  });
});
