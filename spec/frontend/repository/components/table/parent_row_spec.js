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
    provide: {
      refType: 'heads',
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
  it.each`
    path                        | to
    ${'app'}                    | ${'/-/tree/main'}
    ${'app/assets'}             | ${'/-/tree/main/app'}
    ${'app/assets#/test'}       | ${'/-/tree/main/app/assets%23'}
    ${'app/assets#/test/world'} | ${'/-/tree/main/app/assets%23/test'}
  `('renders link in $path to $to', ({ path, to }) => {
    factory(path);

    expect(vm.findComponent(RouterLinkStub).props().to).toBe(`${to}?ref_type=heads`);
  });

  it('pushes new router when clicking row', () => {
    factory('app/assets');

    vm.find('td').trigger('click');

    expect($router.push).toHaveBeenCalledWith('/-/tree/main/app?ref_type=heads');
  });

  // We test that it does not get called when clicking any internal
  // links as this was causing multipe routes to get pushed
  it('does not trigger router.push when clicking link', () => {
    factory('app/assets');

    vm.find('a').trigger('click');

    expect($router.push).not.toHaveBeenCalled();
  });

  it('renders loading icon when loading parent', () => {
    factory('app/assets', 'app');

    expect(vm.findComponent(GlLoadingIcon).exists()).toBe(true);
  });
});
