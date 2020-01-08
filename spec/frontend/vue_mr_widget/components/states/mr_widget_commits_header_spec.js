import { shallowMount } from '@vue/test-utils';
import CommitsHeader from '~/vue_merge_request_widget/components/states/commits_header.vue';
import Icon from '~/vue_shared/components/icon.vue';

describe('Commits header component', () => {
  let wrapper;

  const createComponent = props => {
    wrapper = shallowMount(CommitsHeader, {
      sync: false,
      propsData: {
        isSquashEnabled: false,
        targetBranch: 'master',
        commitsCount: 5,
        isFastForwardEnabled: false,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findHeaderWrapper = () => wrapper.find('.js-mr-widget-commits-count');
  const findCommitToggle = () => wrapper.find('.commit-edit-toggle');
  const findIcon = () => wrapper.find(Icon);
  const findCommitsCountMessage = () => wrapper.find('.commits-count-message');
  const findTargetBranchMessage = () => wrapper.find('.label-branch');
  const findModifyButton = () => wrapper.find('.modify-message-button');

  describe('when fast-forward is enabled', () => {
    beforeEach(() => {
      createComponent({
        isFastForwardEnabled: true,
        isSquashEnabled: true,
      });
    });

    it('has commits count message showing 1 commit', () => {
      expect(findCommitsCountMessage().text()).toBe('1 commit');
    });

    it('has button with modify commit message', () => {
      expect(findModifyButton().text()).toBe('Modify commit message');
    });

    it('does not have merge commit part of the message', () => {
      expect(findHeaderWrapper().text()).not.toContain('1 merge commit');
    });
  });

  describe('when collapsed', () => {
    it('toggle has aria-label equal to Expand', () => {
      createComponent();

      expect(findCommitToggle().attributes('aria-label')).toBe('Expand');
    });

    it('has a chevron-right icon', () => {
      createComponent();
      wrapper.setData({ expanded: false });

      return wrapper.vm.$nextTick().then(() => {
        expect(findIcon().props('name')).toBe('chevron-right');
      });
    });

    describe('when squash is disabled', () => {
      beforeEach(() => {
        createComponent();
      });

      it('has commits count message showing correct amount of commits', () => {
        expect(findCommitsCountMessage().text()).toBe('5 commits');
      });

      it('has button with modify merge commit message', () => {
        expect(findModifyButton().text()).toBe('Modify merge commit');
      });
    });

    describe('when squash is enabled', () => {
      beforeEach(() => {
        createComponent({ isSquashEnabled: true });
      });

      it('has commits count message showing one commit when squash is enabled', () => {
        expect(findCommitsCountMessage().text()).toBe('1 commit');
      });

      it('has button with modify commit messages text', () => {
        expect(findModifyButton().text()).toBe('Modify commit messages');
      });
    });

    it('has correct target branch displayed', () => {
      createComponent();

      expect(findTargetBranchMessage().text()).toBe('master');
    });

    it('does has merge commit part of the message', () => {
      expect(findHeaderWrapper().text()).toContain('1 merge commit');
    });
  });

  describe('when expanded', () => {
    beforeEach(() => {
      createComponent();
      wrapper.setData({ expanded: true });
    });

    it('toggle has aria-label equal to collapse', done => {
      wrapper.vm.$nextTick(() => {
        expect(findCommitToggle().attributes('aria-label')).toBe('Collapse');
        done();
      });
    });

    it('has a chevron-down icon', done => {
      wrapper.vm.$nextTick(() => {
        expect(findIcon().props('name')).toBe('chevron-down');
        done();
      });
    });

    it('has a collapse text', done => {
      wrapper.vm.$nextTick(() => {
        expect(findHeaderWrapper().text()).toBe('Collapse');
        done();
      });
    });
  });
});
