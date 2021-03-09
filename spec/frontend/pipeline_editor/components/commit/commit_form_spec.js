import { GlFormInput, GlFormTextarea } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';

import CommitForm from '~/pipeline_editor/components/commit/commit_form.vue';

import { mockCommitMessage, mockDefaultBranch } from '../../mock_data';

describe('Pipeline Editor | Commit Form', () => {
  let wrapper;

  const createComponent = ({ props = {} } = {}, mountFn = shallowMount) => {
    wrapper = mountFn(CommitForm, {
      propsData: {
        defaultMessage: mockCommitMessage,
        currentBranch: mockDefaultBranch,
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

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when the form is displayed', () => {
    beforeEach(async () => {
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
    beforeEach(async () => {
      createComponent({}, mount);
    });

    it('emits an event when the form submits', () => {
      findSubmitBtn().trigger('click');

      expect(wrapper.emitted('submit')[0]).toEqual([
        {
          message: mockCommitMessage,
          targetBranch: mockDefaultBranch,
          openMergeRequest: false,
        },
      ]);
    });

    it('emits an event when the form resets', () => {
      findCancelBtn().trigger('click');

      expect(wrapper.emitted('cancel')).toHaveLength(1);
    });
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
          targetBranch: anotherBranch,
          openMergeRequest: true,
        },
      ]);
    });

    it('when the commit message is empty, submit button is disabled', async () => {
      await findCommitTextarea().setValue('');

      expect(findSubmitBtn().attributes('disabled')).toBe('disabled');
    });
  });
});
