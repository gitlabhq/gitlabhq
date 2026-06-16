import { nextTick } from 'vue';
import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitListHeader from '~/projects/commits/components/commit_list_header.vue';
import CommitFilteredSearch from '~/projects/commits/components/commit_filtered_search.vue';
import CommitListBreadcrumb from '~/projects/commits/components/commit_list_breadcrumb.vue';
import OpenMrBadge from '~/badges/components/open_mr_badge/open_mr_badge.vue';
import RefSelector from '~/ref/components/ref_selector.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

const commitsFeedPath = '/gitlab-org/gitlab/-/commits/main.atom';
const browseFilesPath = '/gitlab-org/gitlab/-/tree/main';

describe('CommitListHeader', () => {
  let wrapper;

  const mockRouter = {
    push: jest.fn(),
  };

  const createComponent = ({
    filePath = 'README.md',
    currentRef = '',
    refType = 'heads',
    routePath = '/dev/README.md',
    routeParams = {},
  } = {}) => {
    wrapper = shallowMountExtended(CommitListHeader, {
      provide: {
        projectRootPath: 'gitlab-org/gitlab',
        projectFullPath: 'gitlab-org/gitlab',
        projectId: '1',
        escapedRef: 'feature',
        refType,
        rootRef: 'main',
        browseFilesPath,
        commitsFeedPath,
      },
      propsData: {
        currentRef,
        filePath,
      },
      mocks: {
        $router: mockRouter,
        $route: {
          path: routePath,
          params: {
            path: filePath,
            ...routeParams,
          },
        },
      },
    });
  };

  const findCommitFilteredSearch = () => wrapper.findComponent(CommitFilteredSearch);
  const findOverflowMenu = () => wrapper.findComponent(GlDisclosureDropdown);
  const findBrowseFilesItem = () => wrapper.findByTestId('browse-files-link');
  const findCommitsFeedItem = () => wrapper.findByTestId('commits-feed-link');
  const findCommitListBreadcrumb = () => wrapper.findComponent(CommitListBreadcrumb);
  const findRefSelector = () => wrapper.findComponent(RefSelector);
  const findOpenMrBadge = () => wrapper.findComponent(OpenMrBadge);

  beforeEach(() => {
    createComponent();
  });

  describe('template', () => {
    it('renders the breadcrumb component', () => {
      expect(findCommitListBreadcrumb().exists()).toBe(true);
    });

    it('renders the page title', () => {
      expect(wrapper.find('h1').text()).toBe('Commits');
    });

    it('renders CommitFilteredSearch component', () => {
      expect(findCommitFilteredSearch().exists()).toBe(true);
    });

    it('renders overflow menu with correct props', () => {
      const overflowMenu = findOverflowMenu();

      expect(overflowMenu.props()).toMatchObject({
        icon: 'ellipsis_v',
        toggleText: 'Actions',
        textSrOnly: true,
        noCaret: true,
        category: 'tertiary',
        placement: 'bottom-end',
      });
    });

    it('renders browse files dropdown item with correct props', () => {
      const browseFilesItem = findBrowseFilesItem();

      expect(browseFilesItem.props('item')).toMatchObject({
        text: 'Browse files',
        icon: 'folder-open',
        href: browseFilesPath,
        extraAttrs: {
          'data-testid': 'browse-files-link',
        },
      });
    });

    it('renders commits feed dropdown item with correct props', () => {
      const commitsFeedItem = findCommitsFeedItem();

      expect(commitsFeedItem.props('item')).toMatchObject({
        text: 'Commits feed',
        icon: 'rss',
        href: commitsFeedPath,
        extraAttrs: {
          'data-testid': 'commits-feed-link',
        },
      });
    });

    it('renders RefSelector with correct props', () => {
      expect(findRefSelector().props()).toMatchObject({
        projectId: '1',
        useSymbolicRefNames: true,
        defaultBranch: 'main',
        queryParams: { sort: 'updated_desc' },
        value: 'refs/heads/feature',
      });
    });

    describe('refSelectorValue', () => {
      it('uses escapedRef when currentRef is not provided', () => {
        createComponent();
        expect(findRefSelector().props('value')).toBe('refs/heads/feature');
      });

      it('uses currentRef when provided', () => {
        createComponent({ currentRef: 'develop' });
        expect(findRefSelector().props('value')).toBe('refs/heads/develop');
      });

      it('uses currentRef without refType prefix when refType is absent', () => {
        createComponent({ currentRef: 'develop', refType: '' });
        expect(findRefSelector().props('value')).toBe('develop');
      });

      it('falls back to escapedRef when currentRef is empty string', () => {
        createComponent({ currentRef: '' });
        expect(findRefSelector().props('value')).toBe('refs/heads/feature');
      });
    });

    describe('open mr badge', () => {
      it('renders OpenMrBadge with correct props', () => {
        expect(findOpenMrBadge().exists()).toBe(true);
        expect(findOpenMrBadge().props()).toMatchObject({
          projectPath: 'gitlab-org/gitlab',
          blobPath: 'README.md',
          currentRef: 'feature',
        });
      });

      it('does not render OpenMrBadge when there is no file path', () => {
        createComponent({ filePath: '' });
        expect(findOpenMrBadge().exists()).toBe(false);
      });
    });
  });

  describe('events', () => {
    it('emits filter event when CommitFilteredSearch emits filter', () => {
      const filterTokens = [{ type: 'author', value: { data: 'test-author' } }];

      findCommitFilteredSearch().vm.$emit('filter', filterTokens);

      expect(wrapper.emitted('filter')).toEqual([[filterTokens]]);
    });

    it('updates router with correct props when ref changes', async () => {
      findRefSelector().vm.$emit('input', 'dev');
      await nextTick();

      expect(mockRouter.push).toHaveBeenCalledWith({
        path: '/dev/README.md',
        query: {},
      });
    });

    it('sets ref_type query param for symbolic refs', async () => {
      findRefSelector().vm.$emit('input', 'refs/tags/v1.0');
      await nextTick();

      expect(mockRouter.push).toHaveBeenCalledWith({
        path: '/v1.0/README.md',
        query: { ref_type: 'tags' },
      });
    });

    it('emits ref-change event with the actual ref name', async () => {
      findRefSelector().vm.$emit('input', 'refs/heads/new-branch');
      await nextTick();

      expect(wrapper.emitted('ref-change')).toEqual([['new-branch']]);
    });

    it('emits ref-change event with non-symbolic ref name', async () => {
      findRefSelector().vm.$emit('input', 'dev');
      await nextTick();

      expect(wrapper.emitted('ref-change')).toEqual([['dev']]);
    });

    it('properly encodes special characters in ref when updating router', async () => {
      findRefSelector().vm.$emit('input', 'feat/selected-#-ref-#');
      await nextTick();

      expect(mockRouter.push).toHaveBeenCalledWith({
        path: '/feat%2Fselected-%23-ref-%23/README.md',
        query: {},
      });
    });

    it('encodes slashes in ref so it becomes a single path segment', async () => {
      findRefSelector().vm.$emit('input', 'refs/heads/feature/my-branch');
      await nextTick();

      expect(mockRouter.push).toHaveBeenCalledWith({
        path: '/feature%2Fmy-branch/README.md',
        query: { ref_type: 'heads' },
      });
    });
  });
});
