import { escape } from 'lodash';
import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import { extendedWrapper } from 'jest/helpers/vue_test_utils_helper';
import { sprintf } from '~/locale';
import ValidationSegment, { i18n } from '~/pipeline_editor/components/info/validation_segment.vue';
import { CI_CONFIG_STATUS_INVALID } from '~/pipeline_editor/constants';
import { mockYmlHelpPagePath, mergeUnwrappedCiConfig } from '../../mock_data';

describe('~/pipeline_editor/components/info/validation_segment.vue', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(ValidationSegment, {
        provide: {
          ymlHelpPagePath: mockYmlHelpPagePath,
        },
        propsData: {
          ciConfig: mergeUnwrappedCiConfig(),
          loading: false,
          ...props,
        },
      }),
    );
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findLearnMoreLink = () => wrapper.findByTestId('learnMoreLink');
  const findValidationMsg = () => wrapper.findByTestId('validationMsg');

  it('shows the loading state', () => {
    createComponent({ loading: true });

    expect(wrapper.text()).toBe(i18n.loading);
  });

  describe('when config is valid', () => {
    beforeEach(() => {
      createComponent({});
    });

    it('has check icon', () => {
      expect(findIcon().props('name')).toBe('check');
    });

    it('shows a message for valid state', () => {
      expect(findValidationMsg().text()).toContain(i18n.valid);
    });

    it('shows the learn more link', () => {
      expect(findLearnMoreLink().attributes('href')).toBe(mockYmlHelpPagePath);
      expect(findLearnMoreLink().text()).toBe(i18n.learnMore);
    });
  });

  describe('when config is not valid', () => {
    beforeEach(() => {
      createComponent({
        ciConfig: mergeUnwrappedCiConfig({
          status: CI_CONFIG_STATUS_INVALID,
        }),
      });
    });

    it('has warning icon', () => {
      expect(findIcon().props('name')).toBe('warning-solid');
    });

    it('has message for invalid state', () => {
      expect(findValidationMsg().text()).toBe(i18n.invalid);
    });

    it('shows an invalid state with an error', () => {
      const firstError = 'First Error';
      const secondError = 'Second Error';

      createComponent({
        ciConfig: mergeUnwrappedCiConfig({
          status: CI_CONFIG_STATUS_INVALID,
          errors: [firstError, secondError],
        }),
      });

      // Test the error is shown _and_ the string matches
      expect(findValidationMsg().text()).toContain(firstError);
      expect(findValidationMsg().text()).toBe(
        sprintf(i18n.invalidWithReason, { reason: firstError }),
      );
    });

    it('shows an invalid state with an error while preventing XSS', () => {
      const evilError = '<script>evil();</script>';

      createComponent({
        ciConfig: mergeUnwrappedCiConfig({
          status: CI_CONFIG_STATUS_INVALID,
          errors: [evilError],
        }),
      });

      const { innerHTML } = findValidationMsg().element;

      expect(innerHTML).not.toContain(evilError);
      expect(innerHTML).toContain(escape(evilError));
    });

    it('shows the learn more link', () => {
      expect(findLearnMoreLink().attributes('href')).toBe(mockYmlHelpPagePath);
      expect(findLearnMoreLink().text()).toBe('Learn more');
    });
  });
});
