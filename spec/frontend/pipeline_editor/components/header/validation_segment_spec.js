import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { escape } from 'lodash';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { sprintf } from '~/locale';
import ValidationSegment, {
  i18n,
} from '~/pipeline_editor/components/header/validation_segment.vue';
import {
  CI_CONFIG_STATUS_INVALID,
  EDITOR_APP_STATUS_EMPTY,
  EDITOR_APP_STATUS_INVALID,
  EDITOR_APP_STATUS_LOADING,
  EDITOR_APP_STATUS_VALID,
} from '~/pipeline_editor/constants';
import { mockYmlHelpPagePath, mergeUnwrappedCiConfig, mockCiYml } from '../../mock_data';

describe('Validation segment component', () => {
  let wrapper;

  const createComponent = ({ props = {}, appStatus }) => {
    wrapper = extendedWrapper(
      shallowMount(ValidationSegment, {
        provide: {
          ymlHelpPagePath: mockYmlHelpPagePath,
        },
        propsData: {
          ciConfig: mergeUnwrappedCiConfig(),
          ciFileContent: mockCiYml,
          ...props,
        },
        // Simulate graphQL client query result
        data() {
          return {
            appStatus,
          };
        },
      }),
    );
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findLearnMoreLink = () => wrapper.findByTestId('learnMoreLink');
  const findValidationMsg = () => wrapper.findByTestId('validationMsg');

  afterEach(() => {
    wrapper.destroy();
  });

  it('shows the loading state', () => {
    createComponent({ appStatus: EDITOR_APP_STATUS_LOADING });

    expect(wrapper.text()).toBe(i18n.loading);
  });

  describe('when config is empty', () => {
    beforeEach(() => {
      createComponent({ appStatus: EDITOR_APP_STATUS_EMPTY });
    });

    it('has check icon', () => {
      expect(findIcon().props('name')).toBe('check');
    });

    it('shows a message for empty state', () => {
      expect(findValidationMsg().text()).toBe(i18n.empty);
    });
  });

  describe('when config is valid', () => {
    beforeEach(() => {
      createComponent({ appStatus: EDITOR_APP_STATUS_VALID });
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

  describe('when config is invalid', () => {
    beforeEach(() => {
      createComponent({
        appStatus: EDITOR_APP_STATUS_INVALID,
      });
    });
    it('has warning icon', () => {
      expect(findIcon().props('name')).toBe('warning-solid');
    });

    it('has message for invalid state', () => {
      expect(findValidationMsg().text()).toBe(i18n.invalid);
    });

    it('shows the learn more link', () => {
      expect(findLearnMoreLink().attributes('href')).toBe(mockYmlHelpPagePath);
      expect(findLearnMoreLink().text()).toBe('Learn more');
    });

    describe('with multiple errors', () => {
      const firstError = 'First Error';
      const secondError = 'Second Error';

      beforeEach(() => {
        createComponent({
          props: {
            ciConfig: mergeUnwrappedCiConfig({
              status: CI_CONFIG_STATUS_INVALID,
              errors: [firstError, secondError],
            }),
          },
        });
      });
      it('shows an invalid state with an error', () => {
        // Test the error is shown _and_ the string matches
        expect(findValidationMsg().text()).toContain(firstError);
        expect(findValidationMsg().text()).toBe(
          sprintf(i18n.invalidWithReason, { reason: firstError }),
        );
      });
    });

    describe('with XSS inside the error', () => {
      const evilError = '<script>evil();</script>';

      beforeEach(() => {
        createComponent({
          props: {
            ciConfig: mergeUnwrappedCiConfig({
              status: CI_CONFIG_STATUS_INVALID,
              errors: [evilError],
            }),
          },
        });
      });
      it('shows an invalid state with an error while preventing XSS', () => {
        const { innerHTML } = findValidationMsg().element;

        expect(innerHTML).not.toContain(evilError);
        expect(innerHTML).toContain(escape(evilError));
      });
    });
  });
});
