import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlBreadcrumb } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Breadcrumbs from '~/repository/components/header_area/breadcrumbs.vue';
import projectPathQuery from '~/repository/queries/project_path.query.graphql';
import createApolloProvider from 'helpers/mock_apollo_helper';

const defaultMockRoute = {
  name: 'blobPath',
};

const TEST_PROJECT_PATH = 'test-project/path';

Vue.use(VueApollo);

describe('Repository breadcrumbs component', () => {
  let wrapper;

  const factory = ({
    currentPath,
    extraProps = {},
    mockRoute = {},
    projectRootPath = TEST_PROJECT_PATH,
  } = {}) => {
    const apolloProvider = createApolloProvider();

    apolloProvider.clients.defaultClient.cache.writeQuery({
      query: projectPathQuery,
      data: {
        projectPath: TEST_PROJECT_PATH,
      },
    });

    wrapper = shallowMount(Breadcrumbs, {
      apolloProvider,
      provide: {
        projectRootPath,
        isBlobView: extraProps.isBlobView,
      },
      propsData: {
        currentPath,
        ...extraProps,
      },
      mocks: {
        $route: {
          defaultMockRoute,
          ...mockRoute,
        },
      },
    });
  };

  const findGLBreadcrumb = () => wrapper.findComponent(GlBreadcrumb);

  beforeEach(() => {
    factory({
      currentPath: '/',
    });
  });

  it('renders the `gl-breadcrumb` component', () => {
    expect(findGLBreadcrumb().exists()).toBe(true);
    expect(findGLBreadcrumb().props()).toMatchObject({
      items: [
        {
          path: '/',
          text: '',
          to: '/-/tree',
        },
      ],
    });
  });

  it('renders the correct breadcrumbs for an instance with relative URL', () => {
    factory({
      projectRootPath: 'repo/test-project/path',
    });

    expect(findGLBreadcrumb().exists()).toBe(true);
    expect(findGLBreadcrumb().props()).toMatchObject({
      items: [
        {
          path: '/',
          text: '',
          to: '/-/tree',
        },
      ],
    });
  });

  it.each`
    path                        | linkCount
    ${'/'}                      | ${1}
    ${'app'}                    | ${2}
    ${'app/assets'}             | ${3}
    ${'app/assets/javascripts'} | ${4}
  `('renders $linkCount links for path $path', ({ path, linkCount }) => {
    factory({
      currentPath: path,
    });
    expect(findGLBreadcrumb().props('items')).toHaveLength(linkCount);
  });

  it.each`
    currentPath           | expectedPath | routeName
    ${'foo'}              | ${'foo'}     | ${'treePath'}
    ${'foo/bar'}          | ${'foo/bar'} | ${'treePath'}
    ${'foo/bar/index.js'} | ${'foo/bar'} | ${'blobPath'}
  `(
    'sets data-current-path to $expectedPath when path is $currentPath and routeName is $routeName',
    ({ currentPath, expectedPath, routeName }) => {
      factory({
        currentPath,
        mockRoute: {
          name: routeName,
        },
      });

      expect(findGLBreadcrumb().attributes('data-current-path')).toBe(expectedPath);
    },
  );

  describe('copy-to-clipboard icon button', () => {
    it.each`
      description                                  | currentPath        | expected
      ${'does not render button when path empty'}  | ${''}              | ${false}
      ${'renders button that copies current path'} | ${'/path/to/file'} | ${true}
    `('when currentPath is "$currentPath", $description', ({ currentPath, expected }) => {
      factory({
        currentPath,
      });
      expect(findGLBreadcrumb().props('showClipboardButton')).toBe(expected);
      if (expected) {
        expect(findGLBreadcrumb().props('pathToCopy')).toBe(currentPath);
        expect(findGLBreadcrumb().props('clipboardTooltipText')).toBe('Copy file path');
      }
    });
  });
});
