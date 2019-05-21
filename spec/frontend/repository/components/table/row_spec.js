import { shallowMount, RouterLinkStub } from '@vue/test-utils';
import TableRow from '~/repository/components/table/row.vue';

let vm;
let $router;

function factory(propsData = {}) {
  $router = {
    push: jest.fn(),
  };

  vm = shallowMount(TableRow, {
    propsData,
    mocks: {
      $router,
    },
    stubs: {
      RouterLink: RouterLinkStub,
    },
  });

  vm.setData({ ref: 'master' });
}

describe('Repository table row component', () => {
  afterEach(() => {
    vm.destroy();
  });

  it('renders table row', () => {
    factory({
      id: 1,
      path: 'test',
      type: 'file',
    });

    expect(vm.element).toMatchSnapshot();
  });

  it.each`
    type        | component         | componentName
    ${'folder'} | ${RouterLinkStub} | ${'RouterLink'}
    ${'file'}   | ${'a'}            | ${'hyperlink'}
    ${'commit'} | ${'a'}            | ${'hyperlink'}
  `('renders a $componentName for type $type', ({ type, component }) => {
    factory({
      id: 1,
      path: 'test',
      type,
    });

    expect(vm.find(component).exists()).toBe(true);
  });

  it.each`
    type        | pushes
    ${'folder'} | ${true}
    ${'file'}   | ${false}
    ${'commit'} | ${false}
  `('pushes new router if type $type is folder', ({ type, pushes }) => {
    factory({
      id: 1,
      path: 'test',
      type,
    });

    vm.trigger('click');

    if (pushes) {
      expect($router.push).toHaveBeenCalledWith({ path: '/tree/master/test' });
    } else {
      expect($router.push).not.toHaveBeenCalled();
    }
  });

  it('renders commit ID for submodule', () => {
    factory({
      id: 1,
      path: 'test',
      type: 'commit',
    });

    expect(vm.find('.commit-sha').text()).toContain('1');
  });
});
