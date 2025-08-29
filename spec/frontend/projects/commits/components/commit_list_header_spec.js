import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitListHeader from '~/projects/commits/components/commit_list_header.vue';
import CommitFilteredSearch from '~/projects/commits/components/commit_filtered_search.vue';
import CommitListBreadcrumb from '~/projects/commits/components/commit_list_breadcrumb.vue';
import OpenMrBadge from '~/badges/components/open_mr_badge/open_mr_badge.vue';
import RefSelector from '~/ref/components/ref_selector.vue';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

const commitsFeedPath = '/gitlab-org/gitlab/-/commits/main.atom';
const browseFilesPath = '/gitlab-org/gitlab/-/tree/main';

describe('CommitListHeader', () => {
  let wrapper;

  const defaultProvide = {
    projectRootPath: 'gitlab-org/gitlab',
    projectFullPath: 'gitlab-org/gitlab',
    projectId: '1',
    escapedRef: 'feature',
    refType: 'heads',
    rootRef: 'main',
    browseFilesPath,
    commitsFeedPath,
    path: './README.md',
  };

  const createComponent = (provide = {}) => {
    wrapper = shallowMountExtended(CommitListHeader, {
      provide: {
        ...defaultProvide,
        ...provide,
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

    it('renders OpenMrBadge with correct props', () => {
      expect(findOpenMrBadge().exists()).toBe(true);
      expect(findOpenMrBadge().props()).toMatchObject({
        projectPath: 'gitlab-org/gitlab',
        blobPath: './README.md',
        currentRef: 'feature',
      });
    });
  });

  describe('events', () => {
    it('emits filter event when CommitFilteredSearch emits filter', () => {
      const filterTokens = [{ type: 'author', value: { data: 'test-author' } }];

      findCommitFilteredSearch().vm.$emit('filter', filterTokens);

      expect(wrapper.emitted('filter')).toEqual([[filterTokens]]);
    });

    it('calls visitUrl with correct props when ref changes', () => {
      findRefSelector().vm.$emit('input', 'dev');
      expect(visitUrl).toHaveBeenCalledWith('http://test.host/gitlab-org/gitlab/-/tree/dev');
    });
  });
});
