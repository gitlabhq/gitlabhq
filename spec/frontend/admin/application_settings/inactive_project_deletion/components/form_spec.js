import { GlFormCheckbox } from '@gitlab/ui';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import SettingsForm from '~/admin/application_settings/inactive_project_deletion/components/form.vue';

describe('Form component', () => {
  let wrapper;

  const findEnabledCheckbox = () => wrapper.findComponent(GlFormCheckbox);
  const findProjectDeletionSettings = () =>
    wrapper.findByTestId('inactive-project-deletion-settings');
  const findMinSizeGroup = () => wrapper.findByTestId('min-size-group');
  const findMinSizeInputGroup = () => wrapper.findByTestId('min-size-input-group');
  const findMinSizeInput = () => wrapper.findByTestId('min-size-input');
  const findDeleteAfterMonthsGroup = () => wrapper.findByTestId('delete-after-months-group');
  const findDeleteAfterMonthsInputGroup = () =>
    wrapper.findByTestId('delete-after-months-input-group');
  const findDeleteAfterMonthsInput = () => wrapper.findByTestId('delete-after-months-input');
  const findSendWarningEmailAfterMonthsGroup = () =>
    wrapper.findByTestId('send-warning-email-after-months-group');
  const findSendWarningEmailAfterMonthsInputGroup = () =>
    wrapper.findByTestId('send-warning-email-after-months-input-group');
  const findSendWarningEmailAfterMonthsInput = () =>
    wrapper.findByTestId('send-warning-email-after-months-input');

  const createComponent = (
    mountFn = shallowMountExtended,
    propsData = { deleteInactiveProjects: true },
  ) => {
    wrapper = mountFn(SettingsForm, { propsData });
  };

  describe('Enable inactive project deletion', () => {
    it('has the checkbox', () => {
      createComponent();

      expect(findEnabledCheckbox().exists()).toBe(true);
    });

    it.each([[true], [false]])(
      'when the checkbox is %s then the project deletion settings visibility is set to %s',
      (visible) => {
        createComponent(shallowMountExtended, { deleteInactiveProjects: visible });

        expect(findProjectDeletionSettings().exists()).toBe(visible);
      },
    );
  });

  describe('Minimum size for deletion', () => {
    beforeEach(() => {
      createComponent(mountExtended);
    });

    it('has the minimum size input', () => {
      expect(findMinSizeInput().exists()).toBe(true);
    });

    it('has the field description', () => {
      expect(findMinSizeGroup().text()).toContain('Delete inactive projects that exceed');
    });

    it('has the appended text on the field', () => {
      expect(findMinSizeInputGroup().text()).toContain('MB');
    });

    it.each`
      value    | valid
      ${'0'}   | ${true}
      ${'250'} | ${true}
      ${'-1'}  | ${false}
    `(
      'when the minimum size input has a value of $value, then its validity should be $valid',
      async ({ value, valid }) => {
        await findMinSizeInput().find('input').setValue(value);

        expect(findMinSizeGroup().classes('is-valid')).toBe(valid);
        expect(findMinSizeInput().classes('is-valid')).toBe(valid);
      },
    );
  });

  describe('Delete project after', () => {
    beforeEach(() => {
      createComponent(mountExtended);
    });

    it('has the delete after months input', () => {
      expect(findDeleteAfterMonthsInput().exists()).toBe(true);
    });

    it('has the appended text on the field', () => {
      expect(findDeleteAfterMonthsInputGroup().text()).toContain('months');
    });

    it.each`
      value  | valid
      ${'0'} | ${false}
      ${'1'} | ${false /* Less than the default send warning email months */}
      ${'2'} | ${true}
    `(
      'when the delete after months input has a value of $value, then its validity should be $valid',
      async ({ value, valid }) => {
        await findDeleteAfterMonthsInput().find('input').setValue(value);

        expect(findDeleteAfterMonthsGroup().classes('is-valid')).toBe(valid);
        expect(findDeleteAfterMonthsInput().classes('is-valid')).toBe(valid);
      },
    );
  });

  describe('Send warning email', () => {
    beforeEach(() => {
      createComponent(mountExtended);
    });

    it('has the send warning email after months input', () => {
      expect(findSendWarningEmailAfterMonthsInput().exists()).toBe(true);
    });

    it('has the field description', () => {
      expect(findSendWarningEmailAfterMonthsGroup().text()).toContain(
        'Send email to maintainers after project is inactive for',
      );
    });

    it('has the appended text on the field', () => {
      expect(findSendWarningEmailAfterMonthsInputGroup().text()).toContain('months');
    });

    it.each`
      value  | valid
      ${'2'} | ${true}
      ${'0'} | ${false}
    `(
      'when the minimum size input has a value of $value, then its validity should be $valid',
      async ({ value, valid }) => {
        await findSendWarningEmailAfterMonthsInput().find('input').setValue(value);

        expect(findSendWarningEmailAfterMonthsGroup().classes('is-valid')).toBe(valid);
        expect(findSendWarningEmailAfterMonthsInput().classes('is-valid')).toBe(valid);
      },
    );
  });
});
