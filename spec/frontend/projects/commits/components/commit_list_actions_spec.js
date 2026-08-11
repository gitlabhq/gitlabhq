import { GlDisclosureDropdown } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CommitListActions from '~/projects/commits/components/commit_list_actions.vue';
import OpenMrBadge from '~/badges/components/open_mr_badge/open_mr_badge.vue';

const commitsFeedPath = '/gitlab-org/gitlab/-/commits/main.atom';
const browseFilesPath = '/gitlab-org/gitlab/-/tree/main';

describe('CommitListActions', () => {
  let wrapper;

  const createComponent = ({ filePath = 'README.md' } = {}) => {
    wrapper = shallowMountExtended(CommitListActions, {
      provide: {
        projectFullPath: 'gitlab-org/gitlab',
        escapedRef: 'feature',
        browseFilesPath,
        commitsFeedPath,
      },
      propsData: {
        filePath,
      },
    });
  };

  const findOverflowMenu = () => wrapper.findComponent(GlDisclosureDropdown);
  const findBrowseFilesItem = () => wrapper.findComponentByTestId('browse-files-link');
  const findCommitsFeedItem = () => wrapper.findComponentByTestId('commits-feed-link');
  const findOpenMrBadge = () => wrapper.findComponent(OpenMrBadge);

  beforeEach(() => {
    createComponent();
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
