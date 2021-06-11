import { GlBadge, GlLink, GlIcon } from '@gitlab/ui';
import { shallowMount, RouterLinkStub } from '@vue/test-utils';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import TableRow from '~/repository/components/table/row.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import { FILE_SYMLINK_MODE } from '~/vue_shared/constants';

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
      totalEntries: 10,
    },
    directives: {
      GlHoverLoad: createMockDirective(),
    },
    provide: {
      glFeatures: { refactorBlobViewer: true },
    },
    mocks: {
      $router,
    },
    stubs: {
      RouterLink: RouterLinkStub,
    },
  });

  vm.setData({ escapedRef: 'main' });
}

describe('Repository table row component', () => {
  const findRouterLink = () => vm.find(RouterLinkStub);

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

  it('renders a symlink table row', () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type: 'blob',
      currentPath: '/',
      mode: FILE_SYMLINK_MODE,
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

  it('renders a gl-hover-load directive', () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type: 'blob',
      currentPath: '/',
    });

    const hoverLoadDirective = getBinding(findRouterLink().element, 'gl-hover-load');

    expect(hoverLoadDirective).not.toBeUndefined();
    expect(hoverLoadDirective.value).toBeInstanceOf(Function);
  });

  it.each`
    type        | component         | componentName
    ${'tree'}   | ${RouterLinkStub} | ${'RouterLink'}
    ${'blob'}   | ${RouterLinkStub} | ${'RouterLink'}
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
        path: `/-/tree/main/${encodeURIComponent(path)}`,
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
      expect(vm.find('.tree-item-link').props('to')).toEqual({ path: '/-/tree/main/test%23' });
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
      expect(vm.find(GlIcon).exists()).toBe(true);
      expect(vm.find(GlIcon).props('name')).toBe('lock');
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

    expect(vm.find(FileIcon).props('loading')).toBe(true);
  });
});
