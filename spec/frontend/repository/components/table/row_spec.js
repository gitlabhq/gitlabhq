import { shallowMount, RouterLinkStub } from '@vue/test-utils';
import { GlBadge, GlLink } from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';
import TableRow from '~/repository/components/table/row.vue';
import Icon from '~/vue_shared/components/icon.vue';

jest.mock('~/lib/utils/url_utility');

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

    expect(vm.element).toMatchSnapshot();
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

    expect(vm.find(component).exists()).toBe(true);
  });

  it.each`
    type        | pushes
    ${'tree'}   | ${true}
    ${'file'}   | ${false}
    ${'commit'} | ${false}
  `('pushes new router if type $type is tree', ({ type, pushes }) => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type,
      currentPath: '/',
    });

    vm.trigger('click');

    if (pushes) {
      expect($router.push).toHaveBeenCalledWith({ path: '/tree/master/test' });
    } else {
      expect($router.push).not.toHaveBeenCalled();
    }
  });

  it.each`
    type        | pushes
    ${'tree'}   | ${true}
    ${'file'}   | ${false}
    ${'commit'} | ${false}
  `('calls visitUrl if $type is not tree', ({ type, pushes }) => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type,
      currentPath: '/',
    });

    vm.trigger('click');

    if (pushes) {
      expect(visitUrl).not.toHaveBeenCalled();
    } else {
      const [url, external] = visitUrl.mock.calls[0];
      expect(url).toBe('https://test.com');
      expect(external).toBeFalsy();
    }
  });

  it('renders commit ID for submodule', () => {
    factory({
      id: '1',
      sha: '123',
      path: 'test',
      type: 'commit',
      currentPath: '/',
    });

    expect(vm.find('.commit-sha').text()).toContain('1');
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

    expect(vm.find('a').attributes('href')).toEqual('https://test.com');
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

    expect(vm.find(GlBadge).exists()).toBe(true);
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

    expect(vm.find('a').attributes('href')).toEqual('https://test.com');
    expect(vm.find(GlLink).attributes('href')).toEqual('https://test.com/commit');
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

    expect(vm.find(Icon).exists()).toBe(true);
  });
});
