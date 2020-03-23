import { shallowMount, RouterLinkStub } from '@vue/test-utils';
import { GlBadge, GlLink, GlLoadingIcon } from '@gitlab/ui';
import TableRow from '~/repository/components/table/row.vue';
import Icon from '~/vue_shared/components/icon.vue';

let vm;
let $router;

function factory(propsData = {}) {
  $router = {
    push: jest.fn(),
  };

  vm = shallowMount(TableRow, {
    propsData: {
      ...propsData,
      name: propsData.path,
      projectPath: 'gitlab-org/gitlab-ce',
      url: `https://test.com`,
    },
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
      id: '1',
      sha: '123',
      path: 'test',
      type: 'file',
      currentPath: '/',
    });

    return vm.vm.$nextTick().then(() => {
      expect(vm.element).toMatchSnapshot();
    });
  });

  it('renders table row for path with special character', () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test$/test',
      type: 'file',
      currentPath: 'test$',
    });

    return vm.vm.$nextTick().then(() => {
      expect(vm.element).toMatchSnapshot();
    });
  });

  it.each`
    type        | component         | componentName
    ${'tree'}   | ${RouterLinkStub} | ${'RouterLink'}
    ${'file'}   | ${'a'}            | ${'hyperlink'}
    ${'commit'} | ${'a'}            | ${'hyperlink'}
  `('renders a $componentName for type $type', ({ type, component }) => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type,
      currentPath: '/',
    });

    return vm.vm.$nextTick().then(() => {
      expect(vm.find(component).exists()).toBe(true);
    });
  });

  it.each`
    path
    ${'test#'}
    ${'Änderungen'}
  `('renders link for $path', ({ path }) => {
    factory({
      id: '1',
      sha: '123',
      path,
      type: 'tree',
      currentPath: '/',
    });

    return vm.vm.$nextTick().then(() => {
      expect(vm.find({ ref: 'link' }).props('to')).toEqual({
        path: `/-/tree/master/${encodeURIComponent(path)}`,
      });
    });
  });

  it('renders link for directory with hash', () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test#',
      type: 'tree',
      currentPath: '/',
    });

    return vm.vm.$nextTick().then(() => {
      expect(vm.find('.tree-item-link').props('to')).toEqual({ path: '/-/tree/master/test%23' });
    });
  });

  it('renders commit ID for submodule', () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type: 'commit',
      currentPath: '/',
    });

    return vm.vm.$nextTick().then(() => {
      expect(vm.find('.commit-sha').text()).toContain('1');
    });
  });

  it('renders link with href', () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type: 'blob',
      url: 'https://test.com',
      currentPath: '/',
    });

    return vm.vm.$nextTick().then(() => {
      expect(vm.find('a').attributes('href')).toEqual('https://test.com');
    });
  });

  it('renders LFS badge', () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type: 'commit',
      currentPath: '/',
      lfsOid: '1',
    });

    return vm.vm.$nextTick().then(() => {
      expect(vm.find(GlBadge).exists()).toBe(true);
    });
  });

  it('renders commit and web links with href for submodule', () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type: 'commit',
      url: 'https://test.com',
      submoduleTreeUrl: 'https://test.com/commit',
      currentPath: '/',
    });

    return vm.vm.$nextTick().then(() => {
      expect(vm.find('a').attributes('href')).toEqual('https://test.com');
      expect(vm.find(GlLink).attributes('href')).toEqual('https://test.com/commit');
    });
  });

  it('renders lock icon', () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type: 'tree',
      currentPath: '/',
    });

    vm.setData({ commit: { lockLabel: 'Locked by Root', committedDate: '2019-01-01' } });

    return vm.vm.$nextTick().then(() => {
      expect(vm.find(Icon).exists()).toBe(true);
    });
  });

  it('renders loading icon when path is loading', () => {
    factory({
      id: '1',
      sha: '1',
      path: 'test',
      type: 'tree',
      currentPath: '/',
      loadingPath: 'test',
    });

    expect(vm.find(GlLoadingIcon).exists()).toBe(true);
  });
});
