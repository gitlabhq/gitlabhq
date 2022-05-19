import { shallowMount, mount } from '@vue/test-utils';
import Header from '~/vue_merge_request_widget/components/mr_widget_header.vue';

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

  const commonMrProps = {
    divergedCommitsCount: 1,
    sourceBranch: 'mr-widget-refactor',
    sourceBranchLink: '<a href="/foo/bar/mr-widget-refactor">Link</a>',
    targetBranch: 'main',
    targetBranchPath: '/foo/bar/main',
    statusPath: 'abc',
  };

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
