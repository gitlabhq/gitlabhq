import {
  GlFormTextarea,
  GlModal,
  GlFormCheckbox,
  GlFormInput,
  GlFormRadioGroup,
  GlForm,
  GlSprintf,
  GlFormRadio,
} from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { RENDER_ALL_SLOTS_TEMPLATE, stubComponent } from 'helpers/stub_component';
import setWindowLocation from 'helpers/set_window_location_helper';
import CommitChangesModal from '~/repository/components/commit_changes_modal.vue';
import { sprintf } from '~/locale';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

const initialProps = {
  modalId: 'Delete-blob',
  commitMessage: 'Delete File',
  targetBranch: 'some-target-branch',
  originalBranch: 'main',
  canPushCode: true,
  canPushToBranch: true,
  emptyRepo: false,
  handleFormSubmit: jest.fn(),
};

const { i18n } = CommitChangesModal;

describe('CommitChangesModal', () => {
  let wrapper;

  const createComponentFactory =
    (mountFn) =>
    ({ props, slots } = {}) => {
      wrapper = mountFn(CommitChangesModal, {
        propsData: {
          ...initialProps,
          ...props,
        },
        attrs: {
          static: true,
          visible: true,
        },
        stubs: {
          GlSprintf,
          GlModal: stubComponent(GlModal, { template: RENDER_ALL_SLOTS_TEMPLATE }),
        },
        slots,
      });
    };

  const createComponent = createComponentFactory(shallowMountExtended);
  const createFullComponent = createComponentFactory(mount);

  const findModal = () => wrapper.findComponent(GlModal);
  const findSlot = () => wrapper.findByTestId('test-slot');
  const findForm = () => findModal().findComponent(GlForm);
  const findCommitTextarea = () => findForm().findComponent(GlFormTextarea);
  const findFormRadioGroup = () => findForm().findComponent(GlFormRadioGroup);
  const findRadioGroup = () => findForm().findAllComponents(GlFormRadio);
  const findCurrentBranchRadioOption = () => findRadioGroup().at(0);
  const findNewBranchRadioOption = () => findRadioGroup().at(1);
  const findCreateMrCheckbox = () => findForm().findComponent(GlFormCheckbox);
  const findBranchNameInput = () => findForm().findComponent(GlFormInput);
  const findBranchNameLabel = () => findForm().find(`label[for=branchNameInput]`);
  const findCommitHint = () => wrapper.find('[data-testid="hint"]');
  const findError = () => wrapper.findByTestId('error');
  const findBranchInForkMessage = () =>
    wrapper.findByText('GitLab will create a branch in your fork and start a merge request.');

  const fillForm = async (inputValue = {}) => {
    const { targetText, commitText } = inputValue;

    await findBranchNameInput().vm.$emit('input', targetText);
    await findCommitTextarea().vm.$emit('input', commitText);
  };

  describe('LFS files', () => {
    const lfsTitleText = i18n.LFS_WARNING_TITLE;
    const primaryLfsText = sprintf(i18n.LFS_WARNING_PRIMARY_CONTENT, {
      branch: initialProps.targetBranch,
    });

    const secondaryLfsText = sprintf(i18n.LFS_WARNING_SECONDARY_CONTENT, {
      linkStart: '',
      linkEnd: '',
    });

    describe('LFS warning', () => {
      beforeEach(() => createComponent({ props: { isUsingLfs: true } }));

      it('renders a modal containing LFS text', () => {
        expect(findModal().props('title')).toBe(lfsTitleText);
        expect(findModal().text()).toContain(primaryLfsText);
        expect(findModal().text()).toContain(secondaryLfsText);
      });

      it('hides the LFS content when the continue button is clicked', async () => {
        findModal().vm.$emit('primary', { preventDefault: jest.fn() });
        await nextTick();

        expect(findModal().props('title')).not.toBe(lfsTitleText);
        expect(findModal().text()).not.toContain(primaryLfsText);
        expect(findModal().text()).not.toContain(secondaryLfsText);
      });
    });
  });

  it('renders Modal component', () => {
    createComponent();

    expect(findModal().props()).toMatchObject({
      size: 'md',
      actionPrimary: {
        text: 'Commit changes',
      },
      actionCancel: {
        text: 'Cancel',
      },
    });
    expect(findSlot().exists()).toBe(false);
  });

  it('renders the body slot when one is provided', () => {
    createComponent({
      slots: {
        body: '<div data-testid="test-slot">test body slot</div>',
      },
    });
    expect(findSlot().text()).toBe('test body slot');
  });

  it('renders the form field slot when one is provided', () => {
    createComponent({
      slots: {
        body: '<div data-testid="test-slot">test form fields slot</div>',
      },
    });
    expect(findSlot().text()).toBe('test form fields slot');
  });

  it('disables actionable while loading', () => {
    createComponent({ props: { loading: true } });

    expect(findModal().props('actionPrimary').attributes).toEqual(
      expect.objectContaining({ disabled: true }),
    );
    expect(findModal().props('actionCancel').attributes).toEqual(
      expect.objectContaining({ disabled: true }),
    );
    expect(findCommitTextarea().attributes()).toEqual(
      expect.objectContaining({ disabled: 'true' }),
    );
    expect(findCurrentBranchRadioOption().attributes()).toEqual(
      expect.objectContaining({ disabled: 'true' }),
    );
    expect(findNewBranchRadioOption().attributes()).toEqual(
      expect.objectContaining({ disabled: 'true' }),
    );
  });

  describe('form', () => {
    it('gets passed the path for action attribute', () => {
      createComponent();
      expect(findForm().attributes('action')).toBe(initialProps.actionPath);
    });

    it('shows the correct form fields when repo is empty', () => {
      createComponent({ props: { emptyRepo: true } });
      expect(findCommitTextarea().exists()).toBe(true);
      expect(findRadioGroup().exists()).toBe(false);
      expect(findModal().text()).toContain(
        'GitLab will create a default branch, main, and commit your changes.',
      );
    });

    it('shows the correct form fields when commit to current branch', () => {
      createComponent();
      expect(findCommitTextarea().exists()).toBe(true);
      expect(findRadioGroup()).toHaveLength(2);
      expect(findCurrentBranchRadioOption().text()).toContain(initialProps.originalBranch);
      expect(findNewBranchRadioOption().text()).toBe('Commit to a new branch');
    });

    it('shows the correct form fields when commit to new branch', async () => {
      createComponent();
      expect(findBranchNameInput().exists()).toBe(false);

      findFormRadioGroup().vm.$emit('input', true);
      await nextTick();

      expect(findBranchNameInput().exists()).toBe(true);
      expect(findCreateMrCheckbox().text()).toBe('Create a merge request for this change');
    });

    it('shows the correct form fields when `canPushToBranch` is `false`', () => {
      createComponent({ props: { canPushToBranch: false, canPushCode: true } });
      expect(wrapper.vm.$data.form.fields.branch_name.value).toBe('some-target-branch');
      expect(findCommitTextarea().exists()).toBe(true);
      expect(findRadioGroup().exists()).toBe(false);
      expect(findBranchNameInput().exists()).toBe(true);
      expect(findBranchNameLabel().text()).toBe(
        "You don't have permission to commit to main. Learn more.",
      );
      expect(findCreateMrCheckbox().text()).toBe('Create a merge request for this change');
    });

    describe('when `canPushToCode` is `false`', () => {
      const commitInBranchMessage =
        'Your changes can be committed to main because a merge request is open.';

      it('shows the correct form fields when `branchAllowsCollaboration` is `true`', () => {
        createComponent({ props: { canPushCode: false, branchAllowsCollaboration: true } });
        expect(findCommitTextarea().exists()).toBe(true);
        expect(findRadioGroup().exists()).toBe(false);
        expect(findModal().text()).toContain(commitInBranchMessage);
        expect(findBranchInForkMessage().exists()).toBe(false);
      });

      it('shows the correct form fields when `branchAllowsCollaboration` is `false`', () => {
        createComponent({
          props: {
            canPushCode: false,
            branchAllowsCollaboration: false,
          },
        });
        expect(findCommitTextarea().exists()).toBe(true);
        expect(findRadioGroup().exists()).toBe(false);
        expect(findModal().text()).not.toContain(commitInBranchMessage);
        expect(findBranchInForkMessage().exists()).toBe(true);
      });
    });

    it.each`
      input                     | value                          | emptyRepo | canPushCode | canPushToBranch | exist
      ${'authenticity_token'}   | ${'mock-csrf-token'}           | ${false}  | ${true}     | ${true}         | ${true}
      ${'authenticity_token'}   | ${'mock-csrf-token'}           | ${true}   | ${false}    | ${true}         | ${true}
      ${'original_branch'}      | ${initialProps.originalBranch} | ${false}  | ${true}     | ${true}         | ${true}
      ${'original_branch'}      | ${undefined}                   | ${true}   | ${true}     | ${true}         | ${false}
      ${'create_merge_request'} | ${'1'}                         | ${false}  | ${false}    | ${true}         | ${true}
      ${'create_merge_request'} | ${'1'}                         | ${false}  | ${true}     | ${true}         | ${true}
      ${'create_merge_request'} | ${'1'}                         | ${false}  | ${false}    | ${false}        | ${true}
      ${'create_merge_request'} | ${'1'}                         | ${false}  | ${false}    | ${true}         | ${true}
      ${'create_merge_request'} | ${undefined}                   | ${true}   | ${false}    | ${true}         | ${false}
    `(
      'passes $input as a hidden input with the correct value',
      ({ input, value, emptyRepo, canPushCode, canPushToBranch, exist, fromMergeRequestIid }) => {
        if (fromMergeRequestIid) {
          setWindowLocation(
            `https://gitlab.test/foo?from_merge_request_iid=${fromMergeRequestIid}`,
          );
        }
        createComponent({
          props: {
            emptyRepo,
            canPushCode,
            canPushToBranch,
          },
        });

        const inputMethod = findForm().find(`input[name="${input}"]`);

        if (!exist) {
          expect(inputMethod.exists()).toBe(false);
          return;
        }

        expect(inputMethod.attributes('type')).toBe('hidden');
        expect(inputMethod.attributes('value')).toBe(value);
      },
    );
  });

  describe('hint', () => {
    const targetText = 'some target branch';
    const hintText = 'Try to keep the first line under 52 characters and the others under 72.';
    const charsGenerator = (length) => 'lorem'.repeat(length);

    beforeEach(async () => {
      createFullComponent();
      findFormRadioGroup().vm.$emit('input', true);
      await nextTick();
    });

    it.each`
      commitText                        | exist    | desc
      ${charsGenerator(53)}             | ${true}  | ${'first line length > 52'}
      ${`lorem\n${charsGenerator(73)}`} | ${true}  | ${'other line length > 72'}
      ${charsGenerator(52)}             | ${true}  | ${'other line length = 52'}
      ${`lorem\n${charsGenerator(72)}`} | ${true}  | ${'other line length = 72'}
      ${`lorem`}                        | ${false} | ${'first line length < 53'}
      ${`lorem\nlorem`}                 | ${false} | ${'other line length < 53'}
    `('displays hint $exist for $desc', async ({ commitText, exist }) => {
      await fillForm({ targetText, commitText });

      if (!exist) {
        expect(findCommitHint().exists()).toBe(false);
        return;
      }

      expect(findCommitHint().text()).toBe(hintText);
    });
  });

  describe('form submission', () => {
    beforeEach(async () => {
      createFullComponent();
      await nextTick();
    });

    describe('invalid form', () => {
      beforeEach(async () => {
        findFormRadioGroup().vm.$emit('input', true);
        await nextTick();

        await fillForm({ targetText: '', commitText: '' });
      });

      it('disables submit button', () => {
        expect(findModal().props('actionPrimary').attributes).toEqual(
          expect.objectContaining({ disabled: true }),
        );
      });

      it('does not submit form', () => {
        findModal().vm.$emit('primary', {
          preventDefault: () => {},
        });
        expect(wrapper.emitted('submit-form')).toBeUndefined();
      });
    });

    describe('invalid prop is passed in', () => {
      beforeEach(() => {
        createComponent({ props: { isValid: false } });
      });

      it('disables submit button', () => {
        expect(findModal().props('actionPrimary').attributes).toEqual(
          expect.objectContaining({ disabled: true }),
        );
      });

      it('does not submit form', () => {
        findModal().vm.$emit('primary', {
          preventDefault: () => {},
        });
        expect(wrapper.emitted('submit-form')).toBeUndefined();
      });
    });

    describe('valid form', () => {
      beforeEach(async () => {
        findFormRadioGroup().vm.$emit('input', true);
        await nextTick();
        await fillForm({
          targetText: 'some valid target branch',
          commitText: 'some valid commit message',
        });
      });

      it('enables submit button', () => {
        expect(findModal().props('actionPrimary').attributes).toEqual(
          expect.objectContaining({ disabled: false }),
        );
      });

      it('submits form', async () => {
        await findModal().vm.$emit('primary', { preventDefault: jest.fn() });
        await nextTick();
        const submission = wrapper.emitted('submit-form')[0][0];
        expect(Object.fromEntries(submission)).toStrictEqual({
          authenticity_token: 'mock-csrf-token',
          branch_name: 'some valid target branch',
          branch_selection: 'true',
          commit_message: 'some valid commit message',
          create_merge_request: '1',
          original_branch: 'main',
        });
      });
    });
  });

  describe('error handling', () => {
    const error = 'Test error message';
    beforeEach(() => createComponent({ props: { error } }));

    it('displays error message when error prop is provided', () => {
      expect(findError().text()).toBe(error);
    });

    it('does not display error message when error prop is null', () => {
      createComponent({ props: { error: null } });

      expect(findError().exists()).toBe(false);
    });
  });
});
