import { nextTick } from 'vue';
import { GlFormInput, GlFormTextarea } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';

import CommitForm from '~/ci/pipeline_editor/components/commit/commit_form.vue';

import { mockCommitMessage, mockDefaultBranch } from '../../mock_data';

const scrollIntoViewMock = jest.fn();
HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;

describe('Pipeline Editor | Commit Form', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}, mountFn = shallowMount) => {
    wrapper = mountFn(CommitForm, {
      propsData: {
        defaultMessage: mockCommitMessage,
        currentBranch: mockDefaultBranch,
        hasUnsavedChanges: true,
        isNewCiConfigFile: false,
        ...props,
      },

      // attachTo is required for input/submit events
      attachTo: mountFn === mount ? document.body : null,
    });
  };

  const findCommitTextarea = () => wrapper.findComponent(GlFormTextarea);
  const findBranchInput = () => wrapper.findComponent(GlFormInput);
  const findNewMrCheckbox = () => wrapper.find('[data-testid="new-mr-checkbox"]');
  const findSubmitBtn = () => wrapper.find('[type="submit"]');
  const findCancelBtn = () => wrapper.find('[type="reset"]');

  describe('when the form is displayed', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows a default commit message', () => {
      expect(findCommitTextarea().attributes('value')).toBe(mockCommitMessage);
    });

    it('shows current branch', () => {
      expect(findBranchInput().attributes('value')).toBe(mockDefaultBranch);
    });

    it('shows buttons', () => {
      expect(findSubmitBtn().exists()).toBe(true);
      expect(findCancelBtn().exists()).toBe(true);
    });

    it('does not show a new MR checkbox by default', () => {
      expect(findNewMrCheckbox().exists()).toBe(false);
    });
  });

  describe('when buttons are clicked', () => {
    beforeEach(() => {
      createComponent({}, mount);
    });

    it('emits an event when the form submits', () => {
      findSubmitBtn().trigger('click');

      expect(wrapper.emitted('submit')[0]).toEqual([
        {
          message: mockCommitMessage,
          sourceBranch: mockDefaultBranch,
          openMergeRequest: false,
        },
      ]);
    });

    it('emits an event when the form resets', () => {
      findCancelBtn().trigger('click');

      expect(wrapper.emitted('resetContent')).toHaveLength(1);
    });
  });

  describe('submit button', () => {
    it.each`
      hasUnsavedChanges | isNewCiConfigFile | isDisabled | btnState
      ${false}          | ${false}          | ${true}    | ${'disabled'}
      ${true}           | ${false}          | ${false}   | ${'enabled'}
      ${true}           | ${true}           | ${false}   | ${'enabled'}
      ${false}          | ${true}           | ${false}   | ${'enabled'}
    `(
      'is $btnState when hasUnsavedChanges:$hasUnsavedChanges and isNewCiConfigfile:$isNewCiConfigFile',
      ({ hasUnsavedChanges, isNewCiConfigFile, isDisabled }) => {
        createComponent({ props: { hasUnsavedChanges, isNewCiConfigFile } });

        if (isDisabled) {
          expect(findSubmitBtn().attributes('disabled')).toBeDefined();
        } else {
          expect(findSubmitBtn().attributes('disabled')).toBeUndefined();
        }
      },
    );
  });

  describe('when user inputs values', () => {
    const anotherMessage = 'Another commit message';
    const anotherBranch = 'my-branch';

    beforeEach(() => {
      createComponent({}, mount);

      findCommitTextarea().setValue(anotherMessage);
      findBranchInput().setValue(anotherBranch);
    });

    it('shows a new MR checkbox', () => {
      expect(findNewMrCheckbox().exists()).toBe(true);
    });

    it('emits an event with values', async () => {
      await findNewMrCheckbox().setChecked();
      await findSubmitBtn().trigger('click');

      expect(wrapper.emitted('submit')[0]).toEqual([
        {
          message: anotherMessage,
          sourceBranch: anotherBranch,
          openMergeRequest: true,
        },
      ]);
    });

    it('when the commit message is empty, submit button is disabled', async () => {
      await findCommitTextarea().setValue('');

      expect(findSubmitBtn().attributes('disabled')).toBeDefined();
    });
  });

  describe('when scrollToCommitForm becomes true', () => {
    beforeEach(async () => {
      createComponent();
      wrapper.setProps({ scrollToCommitForm: true });
      await nextTick();
    });

    it('scrolls into view', () => {
      expect(scrollIntoViewMock).toHaveBeenCalledWith({ behavior: 'smooth' });
    });

    it('emits "scrolled-to-commit-form"', () => {
      expect(wrapper.emitted()['scrolled-to-commit-form']).toHaveLength(1);
    });
  });

  describe('commit message reset functionality', () => {
    beforeEach(() => {
      createComponent({}, mount);
    });

    it('resets the commit message to default when resetCommitMessage method is called', async () => {
      const customMessage = 'Custom commit message';

      // Set a custom commit message
      await findCommitTextarea().setValue(customMessage);
      expect(findCommitTextarea().element.value).toBe(customMessage);

      // Call the reset method directly
      wrapper.vm.resetCommitMessage();
      await nextTick();

      // Verify message is reset to default
      expect(findCommitTextarea().element.value).toBe(mockCommitMessage);
    });

    it('only resets the commit message field to default, preserving other form fields', async () => {
      const customMessage = 'Custom commit message';
      const customBranch = 'feature-branch';

      // Set custom values for all fields
      await findCommitTextarea().setValue(customMessage);
      await findBranchInput().setValue(customBranch);

      // Verify initial state
      expect(findCommitTextarea().element.value).toBe(customMessage);
      expect(findBranchInput().element.value).toBe(customBranch);

      // Call the reset method directly
      wrapper.vm.resetCommitMessage();
      await nextTick();

      // Verify only commit message is reset to default, branch is preserved
      expect(findCommitTextarea().element.value).toBe(mockCommitMessage);
      expect(findBranchInput().element.value).toBe(customBranch);
    });

    it('does not interfere with the existing reset button functionality', async () => {
      const customMessage = 'Custom commit message';

      // Set a custom commit message
      await findCommitTextarea().setValue(customMessage);
      expect(findCommitTextarea().element.value).toBe(customMessage);

      // Click the existing reset button
      await findCancelBtn().trigger('click');

      // Verify the resetContent event is still emitted (existing functionality)
      expect(wrapper.emitted('resetContent')).toHaveLength(1);

      // The commit message should still be there (reset button doesn't clear it)
      expect(findCommitTextarea().element.value).toBe(customMessage);
    });
  });
});
