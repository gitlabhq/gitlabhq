import { shallowMount, mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Header from '~/vue_merge_request_widget/components/mr_widget_header.vue';
import WebIdeLink from '~/vue_shared/components/web_ide_link.vue';

describe('MRWidgetHeader', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(Header, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    gon.relative_url_root = '';
  });

  const expectDownloadDropdownItems = () => {
    const downloadEmailPatchesEl = wrapper.find('.js-download-email-patches');
    const downloadPlainDiffEl = wrapper.find('.js-download-plain-diff');

    expect(downloadEmailPatchesEl.text().trim()).toBe('Email patches');
    expect(downloadEmailPatchesEl.attributes('href')).toBe('/mr/email-patches');
    expect(downloadPlainDiffEl.text().trim()).toBe('Plain diff');
    expect(downloadPlainDiffEl.attributes('href')).toBe('/mr/plainDiffPath');
  };

  const commonMrProps = {
    divergedCommitsCount: 1,
    sourceBranch: 'mr-widget-refactor',
    sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">Link</a>',
    targetBranch: 'main',
    targetBranchPath: '/foo/bar/main',
    statusPath: 'abc',
  };

  const findWebIdeButton = () => wrapper.findComponent(WebIdeLink);

  describe('computed', () => {
    describe('shouldShowCommitsBehindText', () => {
      it('return true when there are divergedCommitsCount', () => {
        createComponent({
          mr: {
            divergedCommitsCount: 12,
            sourceBranch: 'mr-widget-refactor',
            sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">Link</a>',
            targetBranch: 'main',
            statusPath: 'abc',
          },
        });

        expect(wrapper.vm.shouldShowCommitsBehindText).toBe(true);
      });

      it('returns false where there are no divergedComits count', () => {
        createComponent({
          mr: {
            divergedCommitsCount: 0,
            sourceBranch: 'mr-widget-refactor',
            sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">Link</a>',
            targetBranch: 'main',
            statusPath: 'abc',
          },
        });

        expect(wrapper.vm.shouldShowCommitsBehindText).toBe(false);
      });
    });

    describe('commitsBehindText', () => {
      it('returns singular when there is one commit', () => {
        wrapper = mount(Header, {
          propsData: {
            mr: commonMrProps,
          },
        });

        expect(wrapper.find('.diverged-commits-count').element.innerHTML).toBe(
          'The source branch is <a href="/foo/bar/main" class="gl-link">1 commit behind</a> the target branch',
        );
      });

      it('returns plural when there is more than one commit', () => {
        wrapper = mount(Header, {
          propsData: {
            mr: {
              ...commonMrProps,
              divergedCommitsCount: 2,
            },
          },
        });
        expect(wrapper.find('.diverged-commits-count').element.innerHTML).toBe(
          'The source branch is <a href="/foo/bar/main" class="gl-link">2 commits behind</a> the target branch',
        );
      });
    });
  });

  describe('template', () => {
    describe('common elements', () => {
      beforeEach(() => {
        createComponent({
          mr: {
            divergedCommitsCount: 12,
            sourceBranch: 'mr-widget-refactor',
            sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">mr-widget-refactor</a>',
            sourceBranchRemoved: false,
            targetBranchPath: 'foo/bar/commits-path',
            targetBranchTreePath: 'foo/bar/tree/path',
            targetBranch: 'main',
            isOpen: true,
            emailPatchesPath: '/mr/email-patches',
            plainDiffPath: '/mr/plainDiffPath',
            statusPath: 'abc',
          },
        });
      });

      it('renders source branch link', () => {
        expect(wrapper.find('.js-source-branch').html()).toContain(
          '<a href="/foo/bar/mr-widget-refactor">mr-widget-refactor</a>',
        );
      });

      it('renders clipboard button', () => {
        expect(wrapper.find('[data-testid="mr-widget-copy-clipboard"]')).not.toBe(null);
      });

      it('renders target branch', () => {
        expect(wrapper.find('.js-target-branch').text().trim()).toBe('main');
      });
    });

    describe('with an open merge request', () => {
      const mrDefaultOptions = {
        iid: 1,
        divergedCommitsCount: 12,
        sourceBranch: 'mr-widget-refactor',
        sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">mr-widget-refactor</a>',
        sourceBranchRemoved: false,
        targetBranchPath: 'foo/bar/commits-path',
        targetBranchTreePath: 'foo/bar/tree/path',
        targetBranch: 'main',
        isOpen: true,
        canPushToSourceBranch: true,
        emailPatchesPath: '/mr/email-patches',
        plainDiffPath: '/mr/plainDiffPath',
        statusPath: 'abc',
        sourceProjectFullPath: 'root/gitlab-ce',
        targetProjectFullPath: 'gitlab-org/gitlab-ce',
        gitpodEnabled: true,
        showGitpodButton: true,
        gitpodUrl: 'http://gitpod.localhost',
      };

      it('renders checkout branch button with modal trigger', () => {
        createComponent({
          mr: { ...mrDefaultOptions },
        });

        const button = wrapper.find('.js-check-out-branch');

        expect(button.text().trim()).toBe('Check out branch');
      });

      it.each([
        [
          'renders web ide button',
          {
            mrProps: {},
            relativeUrl: '',
            webIdeUrl:
              '/-/ide/project/root/gitlab-ce/merge_requests/1?target_project=gitlab-org%2Fgitlab-ce',
          },
        ],
        [
          'renders web ide button with blank target_project, when mr has same target project',
          {
            mrProps: { targetProjectFullPath: 'root/gitlab-ce' },
            relativeUrl: '',
            webIdeUrl: '/-/ide/project/root/gitlab-ce/merge_requests/1?target_project=',
          },
        ],
        [
          'renders web ide button with relative url',
          {
            mrProps: { iid: 2 },
            relativeUrl: '/gitlab',
            webIdeUrl:
              '/gitlab/-/ide/project/root/gitlab-ce/merge_requests/2?target_project=gitlab-org%2Fgitlab-ce',
          },
        ],
      ])('%s', async (_, { mrProps, relativeUrl, webIdeUrl }) => {
        gon.relative_url_root = relativeUrl;
        createComponent({
          mr: { ...mrDefaultOptions, ...mrProps },
        });

        await nextTick();

        expect(findWebIdeButton().props()).toMatchObject({
          showEditButton: false,
          showWebIdeButton: true,
          webIdeText: 'Open in Web IDE',
          gitpodText: 'Open in Gitpod',
          gitpodEnabled: true,
          showGitpodButton: true,
          gitpodUrl: 'http://gitpod.localhost',
          webIdeUrl,
        });
      });

      it('does not render web ide button if source branch is removed', async () => {
        createComponent({ mr: { ...mrDefaultOptions, sourceBranchRemoved: true } });

        await nextTick();

        expect(findWebIdeButton().exists()).toBe(false);
      });

      it('renders download dropdown with links', () => {
        createComponent({
          mr: { ...mrDefaultOptions },
        });

        expectDownloadDropdownItems();
      });
    });

    describe('with a closed merge request', () => {
      beforeEach(() => {
        createComponent({
          mr: {
            divergedCommitsCount: 12,
            sourceBranch: 'mr-widget-refactor',
            sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">mr-widget-refactor</a>',
            sourceBranchRemoved: false,
            targetBranchPath: 'foo/bar/commits-path',
            targetBranchTreePath: 'foo/bar/tree/path',
            targetBranch: 'main',
            isOpen: false,
            emailPatchesPath: '/mr/email-patches',
            plainDiffPath: '/mr/plainDiffPath',
            statusPath: 'abc',
          },
        });
      });

      it('does not render checkout branch button with modal trigger', () => {
        const button = wrapper.find('.js-check-out-branch');

        expect(button.exists()).toBe(false);
      });

      it('renders download dropdown with links', () => {
        expectDownloadDropdownItems();
      });
    });

    describe('without diverged commits', () => {
      beforeEach(() => {
        createComponent({
          mr: {
            divergedCommitsCount: 0,
            sourceBranch: 'mr-widget-refactor',
            sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">mr-widget-refactor</a>',
            sourceBranchRemoved: false,
            targetBranchPath: 'foo/bar/commits-path',
            targetBranchTreePath: 'foo/bar/tree/path',
            targetBranch: 'main',
            isOpen: true,
            emailPatchesPath: '/mr/email-patches',
            plainDiffPath: '/mr/plainDiffPath',
            statusPath: 'abc',
          },
        });
      });

      it('does not render diverged commits info', () => {
        expect(wrapper.find('.diverged-commits-count').exists()).toBe(false);
      });
    });

    describe('with diverged commits', () => {
      beforeEach(() => {
        wrapper = mount(Header, {
          propsData: {
            mr: {
              ...commonMrProps,
              divergedCommitsCount: 12,
              sourceBranchRemoved: false,
              targetBranchPath: 'foo/bar/commits-path',
              targetBranchTreePath: 'foo/bar/tree/path',
              isOpen: true,
              emailPatchesPath: '/mr/email-patches',
              plainDiffPath: '/mr/plainDiffPath',
            },
          },
        });
      });

      it('renders diverged commits info', () => {
        expect(wrapper.find('.diverged-commits-count').text().trim()).toBe(
          'The source branch is 12 commits behind the target branch',
        );

        expect(wrapper.find('.diverged-commits-count a').text().trim()).toBe('12 commits behind');
        expect(wrapper.find('.diverged-commits-count a').attributes('href')).toBe(
          wrapper.vm.mr.targetBranchPath,
        );
      });
    });
  });
});
