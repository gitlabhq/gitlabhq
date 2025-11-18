import VueApollo from 'vue-apollo';
import { GlIcon, GlLink, GlSprintf } from '@gitlab/ui';
import Vue from 'vue';
import { escape } from 'lodash';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import ValidationSegment from '~/ci/pipeline_editor/components/header/validation_segment.vue';
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
  mockMergedConfig,
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
        ciConfig: mockMergedConfig(),
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
  const findValidationMsg = () => wrapper.findByTestId('validation-message');
  const findValidationSegment = () => wrapper.findByTestId('validation-segment');

  it('shows the loading state', () => {
    createComponent({ appStatus: EDITOR_APP_STATUS_LOADING });

    expect(wrapper.text()).toBe('Validating GitLab CI configuration…');
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
      expect(findValidationMsg().text()).toBe(
        "We'll continuously validate your pipeline configuration. The validation results will appear here.",
      );
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
      expect(findValidationMsg().text()).toMatchInterpolatedText(
        'Pipeline syntax is correct. Learn more',
      );
    });

    it('shows the learn more link', () => {
      expect(findHelpLink().text()).toBe('Learn more');
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
      expect(findValidationMsg().text()).toMatchInterpolatedText(
        'This GitLab CI configuration is invalid. Learn more',
      );
    });

    it('shows the learn more link', () => {
      expect(findHelpLink().text()).toBe('Learn more');
      expect(findHelpLink().attributes('href')).toBe(mockYmlHelpPagePath);
    });

    describe('with multiple errors', () => {
      const firstError = 'First Error';
      const secondError = 'Second Error';

      beforeEach(() => {
        createComponent({
          props: {
            ciConfig: mockMergedConfig({
              status: CI_CONFIG_STATUS_INVALID,
              errors: [firstError, secondError],
            }),
          },
        });
      });

      it('shows the learn more link', () => {
        expect(findHelpLink().text()).toBe('Learn more');
        expect(findHelpLink().attributes('href')).toBe(mockYmlHelpPagePath);
      });

      it('shows an invalid state with the first error', () => {
        expect(findValidationMsg().text()).toMatchInterpolatedText(
          `This GitLab CI configuration is invalid: ${firstError}. Learn more`,
        );
      });

      it("doesn't show the second error", () => {
        expect(findValidationMsg().text()).not.toContain(secondError);
      });
    });

    describe('with XSS inside the error', () => {
      const evilError = '<script>evil();</script>';

      beforeEach(() => {
        createComponent({
          props: {
            ciConfig: mockMergedConfig({
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
      expect(findValidationMsg().text()).toMatchInterpolatedText(
        'Unable to validate CI/CD configuration. See the GitLab CI/CD troubleshooting guide for more details.',
      );
    });

    it('shows the time-out icon', () => {
      expect(findIcon().props('name')).toBe('time-out');
    });

    it('shows the link to ci troubleshooting', () => {
      expect(findHelpLink().text()).toBe('GitLab CI/CD troubleshooting guide');
      expect(findHelpLink().attributes('href')).toBe(mockCiTroubleshootingPath);
    });
  });
});
