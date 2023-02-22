import { GlBadge, GlLink, GlIcon, GlIntersectionObserver } from '@gitlab/ui';
import { shallowMount, RouterLinkStub } from '@vue/test-utils';
import { nextTick } from 'vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import TableRow from '~/repository/components/table/row.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import { FILE_SYMLINK_MODE } from '~/vue_shared/constants';
import { ROW_APPEAR_DELAY } from '~/repository/constants';

const COMMIT_MOCK = { lockLabel: 'Locked by Root', committedDate: '2019-01-01' };

let vm;
let $router;

function factory(propsData = {}) {
  $router = {
    push: jest.fn(),
  };

  vm = shallowMount(TableRow, {
    propsData: {
      commitInfo: COMMIT_MOCK,
      ...propsData,
      name: propsData.path,
      projectPath: 'gitlab-org/gitlab-ce',
      url: `https://test.com`,
      totalEntries: 10,
      rowNumber: 123,
    },
    directives: {
      GlHoverLoad: createMockDirective('gl-hover-load'),
    },
    mocks: {
      $router,
    },
    stubs: {
      RouterLink: RouterLinkStub,
    },
  });

  // setData usage is discouraged. See https://gitlab.com/groups/gitlab-org/-/epics/7330 for details
  // eslint-disable-next-line no-restricted-syntax
  vm.setData({ escapedRef: 'main' });
}

describe('Repository table row component', () => {
  const findRouterLink = () => vm.findComponent(RouterLinkStub);
  const findIntersectionObserver = () => vm.findComponent(GlIntersectionObserver);

  afterEach(() => {
    vm.destroy();
  });

  it('renders table row', async () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type: 'file',
      currentPath: '/',
    });

    await nextTick();
    expect(vm.element).toMatchSnapshot();
  });

  it('renders a symlink table row', async () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type: 'blob',
      currentPath: '/',
      mode: FILE_SYMLINK_MODE,
    });

    await nextTick();
    expect(vm.element).toMatchSnapshot();
  });

  it('renders table row for path with special character', async () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test$/test',
      type: 'file',
      currentPath: 'test$',
    });

    await nextTick();
    expect(vm.element).toMatchSnapshot();
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
  `('renders a $componentName for type $type', async ({ type, component }) => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type,
      currentPath: '/',
    });

    await nextTick();
    expect(vm.findComponent(component).exists()).toBe(true);
  });

  it.each`
    path
    ${'test#'}
    ${'Änderungen'}
  `('renders link for $path', async ({ path }) => {
    factory({
      id: '1',
      sha: '123',
      path,
      type: 'tree',
      currentPath: '/',
    });

    await nextTick();
    expect(vm.findComponent({ ref: 'link' }).props('to')).toEqual({
      path: `/-/tree/main/${encodeURIComponent(path)}`,
    });
  });

  it('renders link for directory with hash', async () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test#',
      type: 'tree',
      currentPath: '/',
    });

    await nextTick();
    expect(vm.find('.tree-item-link').props('to')).toEqual({ path: '/-/tree/main/test%23' });
  });

  it('renders commit ID for submodule', async () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type: 'commit',
      currentPath: '/',
    });

    await nextTick();
    expect(vm.find('.commit-sha').text()).toContain('1');
  });

  it('renders link with href', async () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type: 'blob',
      url: 'https://test.com',
      currentPath: '/',
    });

    await nextTick();
    expect(vm.find('a').attributes('href')).toEqual('https://test.com');
  });

  it('renders LFS badge', async () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type: 'commit',
      currentPath: '/',
      lfsOid: '1',
    });

    await nextTick();
    expect(vm.findComponent(GlBadge).exists()).toBe(true);
  });

  it('renders commit and web links with href for submodule', async () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type: 'commit',
      url: 'https://test.com',
      submoduleTreeUrl: 'https://test.com/commit',
      currentPath: '/',
    });

    await nextTick();
    expect(vm.find('a').attributes('href')).toEqual('https://test.com');
    expect(vm.findComponent(GlLink).attributes('href')).toEqual('https://test.com/commit');
  });

  it('renders lock icon', async () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type: 'tree',
      currentPath: '/',
    });

    await nextTick();
    expect(vm.findComponent(GlIcon).exists()).toBe(true);
    expect(vm.findComponent(GlIcon).props('name')).toBe('lock');
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

    expect(vm.findComponent(FileIcon).props('loading')).toBe(true);
  });

  describe('row visibility', () => {
    beforeEach(() => {
      factory({
        id: '1',
        sha: '1',
        path: 'test',
        type: 'tree',
        currentPath: '/',
        commitInfo: null,
      });
    });

    afterAll(() => jest.useRealTimers());

    it('emits a `row-appear` event', async () => {
      const setTimeoutSpy = jest.spyOn(global, 'setTimeout');
      findIntersectionObserver().vm.$emit('appear');

      jest.runAllTimers();

      expect(setTimeoutSpy).toHaveBeenCalledTimes(1);
      expect(setTimeoutSpy).toHaveBeenLastCalledWith(expect.any(Function), ROW_APPEAR_DELAY);
      expect(vm.emitted('row-appear')).toEqual([[123]]);
    });
  });
});
