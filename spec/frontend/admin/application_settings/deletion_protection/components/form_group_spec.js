import { GlLink } from '@gitlab/ui';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { helpPagePath } from '~/helpers/help_page_helper';
import FormGroup from '~/admin/application_settings/deletion_protection/components/form_group.vue';
import {
  I18N_DELETION_PROTECTION,
  DEL_ADJ_PERIOD_MIN_LIMIT_ERROR,
  DEL_ADJ_PERIOD_MAX_LIMIT_ERROR,
} from '~/admin/application_settings/deletion_protection/constants';

describe('Form group component', () => {
  let wrapper;

  const findGlLink = () => wrapper.findComponent(GlLink);
  const findDeletionAdjournedPeriodInput = () => wrapper.findByTestId('deletion_adjourned_period');

  const createComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = mountExtended(FormGroup, {
      propsData: {
        deletionAdjournedPeriod: 7,
        ...props,
      },
      provide,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders an input for setting the deletion adjourned period', () => {
    expect(
      wrapper.findByLabelText(I18N_DELETION_PROTECTION.label, { exact: false }).attributes(),
    ).toMatchObject({
      name: 'application_setting[deletion_adjourned_period]',
      type: 'number',
      min: '1',
      max: '90',
    });
  });

  it('displays the help text', () => {
    expect(wrapper.findByText(I18N_DELETION_PROTECTION.helpText).exists()).toBe(true);
  });

  it('displays the help link', () => {
    expect(findGlLink().text()).toContain(I18N_DELETION_PROTECTION.learnMore);
    expect(findGlLink().attributes('href')).toBe(
      helpPagePath('administration/settings/visibility_and_access_controls', {
        anchor: 'delayed-project-deletion',
      }),
    );
  });

  describe.each`
    value   | errorMessage
    ${''}   | ${DEL_ADJ_PERIOD_MIN_LIMIT_ERROR}
    ${'91'} | ${DEL_ADJ_PERIOD_MAX_LIMIT_ERROR}
    ${'-1'} | ${DEL_ADJ_PERIOD_MIN_LIMIT_ERROR}
  `('when the input has a value of $value', ({ value, errorMessage }) => {
    describe('when input is blured', () => {
      it('displays error message', async () => {
        findDeletionAdjournedPeriodInput().vm.$emit('input', value);
        findDeletionAdjournedPeriodInput().vm.$emit('blur');

        await nextTick();

        expect(findDeletionAdjournedPeriodInput().attributes('aria-invalid')).toBe('true');
        expect(wrapper.findByText(errorMessage).exists()).toBe(true);
      });
    });

    describe('when input emits invalid event', () => {
      it('displays error message, prevents default and focuses on input', async () => {
        findDeletionAdjournedPeriodInput().vm.$emit('input', value);
        const event = {
          preventDefault: jest.fn(),
        };
        const focusSpy = jest.spyOn(findDeletionAdjournedPeriodInput().element, 'focus');

        findDeletionAdjournedPeriodInput().vm.$emit('invalid', event);

        await nextTick();

        expect(findDeletionAdjournedPeriodInput().attributes('aria-invalid')).toBe('true');
        expect(wrapper.findByText(errorMessage).exists()).toBe(true);
        expect(event.preventDefault).toHaveBeenCalled();
        expect(focusSpy).toHaveBeenCalled();
      });
    });
  });

  describe('when input has valid value', () => {
    describe('when input is blured', () => {
      it('does not display error message', async () => {
        findDeletionAdjournedPeriodInput().vm.$emit('input', '50');
        findDeletionAdjournedPeriodInput().vm.$emit('blur');

        await nextTick();

        expect(findDeletionAdjournedPeriodInput().attributes('aria-invalid')).toBe(undefined);
        expect(wrapper.findByText(DEL_ADJ_PERIOD_MIN_LIMIT_ERROR).exists()).toBe(false);
        expect(wrapper.findByText(DEL_ADJ_PERIOD_MAX_LIMIT_ERROR).exists()).toBe(false);
      });
    });

    describe('when input emits invalid event', () => {
      it('does not display error message', async () => {
        findDeletionAdjournedPeriodInput().vm.$emit('input', '50');
        const event = {
          preventDefault: jest.fn(),
        };
        findDeletionAdjournedPeriodInput().vm.$emit('invalid', event);

        await nextTick();

        expect(findDeletionAdjournedPeriodInput().attributes('aria-invalid')).toBe(undefined);
        expect(wrapper.findByText(DEL_ADJ_PERIOD_MIN_LIMIT_ERROR).exists()).toBe(false);
        expect(wrapper.findByText(DEL_ADJ_PERIOD_MAX_LIMIT_ERROR).exists()).toBe(false);
      });
    });
  });
});
