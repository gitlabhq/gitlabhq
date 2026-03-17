import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlBadge, GlLink, GlIcon } from '@gitlab/ui';
import { shallowMount, RouterLinkStub } from '@vue/test-utils';
import refQuery from '~/repository/queries/ref.query.graphql';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import createMockApollo from 'helpers/mock_apollo_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import TableRow from '~/repository/components/table/row.vue';
import FileIcon from '~/vue_shared/components/file_icon.vue';
import { FILE_SYMLINK_MODE } from '~/vue_shared/constants';
import { ROW_APPEAR_DELAY } from '~/repository/constants';
import SkeletonLoader from '~/repository/components/table/skeleton_loader.vue';

const COMMIT_MOCK = { lockLabel: 'Locked by Root', committedDate: '2019-01-01' };

let wrapper;
let $router;

const createMockApolloProvider = (mockData) => {
  Vue.use(VueApollo);
  const apolloProver = createMockApollo([]);
  apolloProver.clients.defaultClient.cache.writeQuery({ query: refQuery, data: { ...mockData } });

  return apolloProver;
};

function factory({
  mockData = { ref: 'main', escapedRef: 'main' },
  propsData = {},
  attrs = {},
} = {}) {
  $router = {
    push: jest.fn(),
  };

  wrapper = shallowMount(TableRow, {
    apolloProvider: createMockApolloProvider(mockData),
    propsData: {
      id: '1',
      sha: '0as4k',
      commitInfo: COMMIT_MOCK,
      name: 'name',
      currentPath: 'gitlab-org/gitlab-ce',
      projectPath: 'gitlab-org/gitlab-ce',
      url: `https://test.com`,
      totalEntries: 10,
      rowNumber: 123,
      path: 'gitlab-org/gitlab-ce',
      type: 'tree',
      ...propsData,
    },
    attrs,
    provide: {
      refType: 'heads',
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
}

describe('Repository table row component', () => {
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findFileIcon = () => wrapper.findComponent(FileIcon);
  const findBadge = () => wrapper.findComponent(GlBadge);
  const findRouterLink = () => wrapper.findComponent(RouterLinkStub);
  const findSkeletonLoaders = () => wrapper.findAllComponents(SkeletonLoader);

  const { bindInternalEventDocument } = useMockInternalEventsTracking();

  describe('skeleton loader', () => {
    it('renders skeleton loaders when commitInfo is not provided', () => {
      factory({ propsData: { commitInfo: null } });

      expect(findSkeletonLoaders()).toHaveLength(2);
    });

    it('does not render skeleton loaders when commitInfo is provided', () => {
      factory(); // commitInfo is provided by default in factory

      expect(findSkeletonLoaders()).toHaveLength(0);
    });
  });

  it('renders table row', () => {
    factory({
      propsData: {
        id: '1',
        sha: '123',
        path: 'test',
        type: 'file',
        currentPath: '/',
      },
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders a symlink table row', () => {
    factory({
      propsData: {
        id: '1',
        sha: '123',
        path: 'test',
        type: 'blob',
        currentPath: '/',
        mode: FILE_SYMLINK_MODE,
      },
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders table row for path with special character', () => {
    factory({
      propsData: {
        id: '1',
        sha: '123',
        path: 'test$/test',
        type: 'file',
        currentPath: 'test$',
      },
    });

    expect(wrapper.element).toMatchSnapshot();
  });

  it('renders a gl-hover-load directive', () => {
    factory({
      propsData: {
        id: '1',
        sha: '123',
        path: 'test',
        type: 'blob',
        currentPath: '/',
      },
    });

    const hoverLoadDirective = getBinding(findRouterLink().element, 'gl-hover-load');

    expect(hoverLoadDirective).not.toBeUndefined();
    expect(hoverLoadDirective.value).toBeInstanceOf(Function);
  });

  it.each(['tree', 'blob'])('renders a RouterLink for type $type', (type) => {
    factory({
      propsData: {
        id: '1',
        sha: '123',
        path: 'test',
        type,
        currentPath: '/',
      },
    });

    expect(wrapper.findComponent(RouterLinkStub).exists()).toBe(true);
  });

  it('renders a hyperlink for type commit', () => {
    factory({
      propsData: {
        id: '1',
        sha: '123',
        path: 'test',
        type: 'commit',
        currentPath: '/',
      },
    });

    expect(wrapper.find('a').exists()).toBe(true);
  });

  it.each`
    path                   | encodedPath
    ${'test#'}             | ${'test%23'}
    ${'Änderungen'}        | ${'%C3%84nderungen'}
    ${'dir%2f_hello__.sh'} | ${'dir%252f_hello__.sh'}
  `('renders link for $path', ({ path, encodedPath }) => {
    factory({
      propsData: {
        id: '1',
        sha: '123',
        path,
        type: 'tree',
        currentPath: '/',
      },
    });

    expect(wrapper.findComponent({ ref: 'link' }).props('to')).toBe(
      `/-/tree/main/${encodedPath}?ref_type=heads`,
    );
  });

  it('renders link for directory with hash', () => {
    factory({
      propsData: {
        id: '1',
        sha: '123',
        path: 'test#',
        type: 'tree',
        currentPath: '/',
      },
    });

    expect(wrapper.find('.tree-item-link').props('to')).toBe(`/-/tree/main/test%23?ref_type=heads`);
  });

  it('renders commit ID for submodule', () => {
    factory({
      propsData: {
        id: '1',
        sha: '123',
        path: 'test',
        type: 'commit',
        currentPath: '/',
      },
    });

    expect(wrapper.find('.commit-sha').text()).toContain('1');
  });

  it('renders link with href', () => {
    factory({
      propsData: {
        id: '1',
        sha: '123',
        path: 'test',
        type: 'blob',
        url: 'https://test.com',
        currentPath: '/',
      },
    });

    expect(wrapper.find('a').attributes('href')).toEqual('https://test.com');
  });

  it('renders LFS badge', () => {
    factory({
      propsData: {
        id: '1',
        sha: '123',
        path: 'test',
        type: 'commit',
        currentPath: '/',
        lfsOid: '1',
      },
    });

    expect(findBadge().exists()).toBe(true);
  });

  it('renders commit and web links with href for submodule', () => {
    factory({
      propsData: {
        id: '1',
        sha: '123',
        path: 'test',
        type: 'commit',
        url: 'https://test.com',
        submoduleTreeUrl: 'https://test.com/commit',
        currentPath: '/',
      },
    });

    expect(wrapper.find('a').attributes('href')).toEqual('https://test.com');
    expect(wrapper.findComponent(GlLink).attributes('href')).toEqual('https://test.com/commit');
  });

  it('renders lock icon', () => {
    factory({
      propsData: {
        id: '1',
        sha: '123',
        path: 'test',
        type: 'tree',
        currentPath: '/',
      },
    });

    expect(findIcon().exists()).toBe(true);
    expect(findIcon().props('name')).toBe('lock');
  });

  it('renders loading icon when path is loading', () => {
    factory({
      propsData: {
        id: '1',
        sha: '1',
        path: 'test',
        type: 'tree',
        currentPath: '/',
        loadingPath: 'test',
      },
    });

    expect(findFileIcon().props('loading')).toBe(true);
  });

  describe('tracking events', () => {
    it('tracks event when file link is clicked', () => {
      factory({
        propsData: {
          id: '1',
          sha: '123',
          path: 'test/test',
          type: 'file',
          currentPath: 'tesf',
        },
      });
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      wrapper.find('tr').trigger('click');

      expect(trackEventSpy).toHaveBeenCalledWith('click_file_list_on_repository_page', {});
    });

    it('tracks event when directory link is clicked', () => {
      factory({
        propsData: {
          id: '1',
          sha: '123',
          path: 'src/components',
          type: 'tree',
          currentPath: '/',
        },
      });
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      wrapper.find('tr').trigger('click');

      expect(trackEventSpy).toHaveBeenCalledWith('click_file_list_on_repository_page', {});
    });

    it('tracks event when submodule link is clicked', () => {
      factory({
        propsData: {
          id: '1',
          sha: '123',
          path: 'external-lib',
          type: 'commit',
          url: 'https://external-repo.com',
          currentPath: '/',
        },
      });
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      wrapper.find('tr').trigger('click');

      expect(trackEventSpy).toHaveBeenCalledWith('click_file_list_on_repository_page', {});
    });
  });

  describe('row visibility', () => {
    afterAll(() => jest.useRealTimers());

    it('emits row-appear on mount when commitInfo is null', () => {
      factory({
        propsData: {
          id: '1',
          sha: '1',
          path: 'test',
          type: 'tree',
          currentPath: '/',
          commitInfo: null,
        },
      });

      jest.advanceTimersByTime(ROW_APPEAR_DELAY);

      expect(wrapper.emitted('row-appear')).toEqual([[123]]);
    });

    it('does not emit row-appear when commitInfo is provided', () => {
      factory({
        propsData: {
          id: '1',
          sha: '1',
          path: 'test',
          type: 'tree',
          currentPath: '/',
        },
      });

      jest.runAllTimers();

      expect(wrapper.emitted('row-appear')).toBeUndefined();
    });
  });

  it('passes data-item-id from attrs to the root tr element', () => {
    jest.useFakeTimers();
    factory({ attrs: { 'data-item-id': 'blob-123-0' } });

    expect(wrapper.find('tr').attributes('data-item-id')).toBe('blob-123-0');
  });
});
