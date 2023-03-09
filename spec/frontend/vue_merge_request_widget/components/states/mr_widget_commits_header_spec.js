import { mount } from '@vue/test-utils';
import { GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import CommitsHeader from '~/vue_merge_request_widget/components/states/commits_header.vue';

describe('Commits header component', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = mount(CommitsHeader, {
      stubs: {
        GlSprintf,
      },
      propsData: {
        isSquashEnabled: false,
        targetBranch: 'main',
        commitsCount: 5,
        isFastForwardEnabled: false,
        ...props,
      },
    });
  };

  const findHeaderWrapper = () => wrapper.find('.js-mr-widget-commits-count');
  const findCommitToggle = () => wrapper.find('.commit-edit-toggle');
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
      expect(wrapper.text()).toContain('1 commit');
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
      expect(findCommitToggle().props('icon')).toBe('chevron-right');
    });

    describe('when squash is disabled', () => {
      beforeEach(() => {
        createComponent();
      });

      it('has commits count message showing correct amount of commits', () => {
        expect(wrapper.text()).toContain('5 commits');
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
        expect(wrapper.text()).toContain('1 commit');
      });

      it('has button with modify commit messages text', () => {
        expect(findModifyButton().text()).toBe('Modify commit messages');
      });
    });

    it('has correct target branch displayed', () => {
      createComponent();

      expect(findTargetBranchMessage().text()).toBe('main');
    });

    it('does has merge commit part of the message', () => {
      createComponent();

      expect(findHeaderWrapper().text()).toContain('1 merge commit');
    });
  });

  describe('when expanded', () => {
    beforeEach(async () => {
      createComponent();
      findCommitToggle().trigger('click');
      await nextTick();
    });

    it('toggle has aria-label equal to collapse', () => {
      expect(findCommitToggle().attributes('aria-label')).toBe('Collapse');
    });

    it('has a chevron-down icon', () => {
      expect(findCommitToggle().props('icon')).toBe('chevron-down');
    });

    it('has a collapse text', () => {
      expect(findHeaderWrapper().text()).toBe('Collapse');
    });
  });
});
