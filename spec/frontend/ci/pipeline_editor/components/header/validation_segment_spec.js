import VueApollo from 'vue-apollo';
import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import Vue from 'vue';
import { escape } from 'lodash';
import { sprintf } from '~/locale';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import ValidationSegment, {
  i18n,
} from '~/ci/pipeline_editor/components/header/validation_segment.vue';
import getAppStatus from '~/ci/pipeline_editor/graphql/queries/client/app_status.query.graphql';
import {
  CI_CONFIG_STATUS_INVALID,
  EDITOR_APP_STATUS_EMPTY,
  EDITOR_APP_STATUS_INVALID,
  EDITOR_APP_STATUS_LOADING,
  EDITOR_APP_STATUS_LINT_UNAVAILABLE,
  EDITOR_APP_STATUS_VALID,
} from '~/ci/pipeline_editor/constants';
import {
  mergeUnwrappedCiConfig,
  mockCiTroubleshootingPath,
  mockCiYml,
  mockYmlHelpPagePath,
} from '../../mock_data';

Vue.use(VueApollo);

describe('Validation segment component', () => {
  let wrapper;

  const mockApollo = createMockApollo();

  const createComponent = ({ props = {}, appStatus = EDITOR_APP_STATUS_INVALID }) => {
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getAppStatus,
      data: {
        app: {
          __typename: 'PipelineEditorApp',
          status: appStatus,
        },
      },
    });

    wrapper = shallowMountExtended(ValidationSegment, {
      apolloProvider: mockApollo,
      provide: {
        ymlHelpPagePath: mockYmlHelpPagePath,
        ciTroubleshootingPath: mockCiTroubleshootingPath,
      },
      propsData: {
        ciConfig: mergeUnwrappedCiConfig(),
        ciFileContent: mockCiYml,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findHelpLink = () => wrapper.findComponent(GlLink);
  const findValidationMsg = () => wrapper.findComponent(GlSprintf);
  const findValidationSegment = () => wrapper.findByTestId('validation-segment');

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

    it('does not render a link', () => {
      expect(findHelpLink().exists()).toBe(false);
    });

    it('shows a message for empty state', () => {
      expect(findValidationSegment().text()).toBe(i18n.empty);
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
      expect(findValidationSegment().text()).toBe(
        sprintf(i18n.valid, { linkStart: '', linkEnd: '' }),
      );
    });

    it('shows the learn more link', () => {
      expect(findValidationMsg().exists()).toBe(true);
      expect(findValidationMsg().text()).toBe('Learn more');
      expect(findHelpLink().attributes('href')).toBe(mockYmlHelpPagePath);
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

    it('shows a message for invalid state', () => {
      expect(findValidationSegment().text()).toBe(
        sprintf(i18n.invalid, { linkStart: '', linkEnd: '' }),
      );
    });

    it('shows the learn more link', () => {
      expect(findValidationMsg().exists()).toBe(true);
      expect(findValidationMsg().text()).toBe('Learn more');
      expect(findHelpLink().attributes('href')).toBe(mockYmlHelpPagePath);
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

      it('shows the learn more link', () => {
        expect(findValidationMsg().exists()).toBe(true);
        expect(findValidationMsg().text()).toBe('Learn more');
        expect(findHelpLink().attributes('href')).toBe(mockYmlHelpPagePath);
      });

      it('shows an invalid state with an error', () => {
        expect(findValidationSegment().text()).toBe(
          sprintf(i18n.invalidWithReason, { reason: firstError, linkStart: '', linkEnd: '' }),
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
        expect(findValidationSegment().html()).not.toContain(evilError);
        expect(findValidationSegment().html()).toContain(escape(evilError));
      });
    });
  });

  describe('when the lint service is unavailable', () => {
    beforeEach(() => {
      createComponent({
        appStatus: EDITOR_APP_STATUS_LINT_UNAVAILABLE,
        props: {
          ciConfig: {},
        },
      });
    });

    it('show a message that the service is unavailable', () => {
      expect(findValidationSegment().text()).toBe(
        sprintf(i18n.unavailableValidation, { linkStart: '', linkEnd: '' }),
      );
    });

    it('shows the time-out icon', () => {
      expect(findIcon().props('name')).toBe('time-out');
    });

    it('shows the link to ci troubleshooting', () => {
      expect(findValidationMsg().exists()).toBe(true);
      expect(findHelpLink().attributes('href')).toBe(mockCiTroubleshootingPath);
    });
  });
});
