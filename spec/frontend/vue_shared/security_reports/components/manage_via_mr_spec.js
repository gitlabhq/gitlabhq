import { GlButton } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { featureToMutationMap } from 'ee_else_ce/security_configuration/components/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { humanize } from '~/lib/utils/text_utility';
import { redirectTo } from '~/lib/utils/url_utility';
import ManageViaMr from '~/vue_shared/security_configuration/components/manage_via_mr.vue';
import { REPORT_TYPE_SAST } from '~/vue_shared/security_reports/constants';
import { buildConfigureSecurityFeatureMockFactory } from './apollo_mocks';

jest.mock('~/lib/utils/url_utility');

Vue.use(VueApollo);

const projectPath = 'namespace/project';

describe('ManageViaMr component', () => {
  let wrapper;

  const findButton = () => wrapper.findComponent(GlButton);

  function createMockApolloProvider(mutation, handler) {
    const requestHandlers = [[mutation, handler]];

    return createMockApollo(requestHandlers);
  }

  function createComponent({
    featureName = 'SAST',
    featureType = 'sast',
    isFeatureConfigured = false,
    variant = undefined,
    category = undefined,
    ...options
  } = {}) {
    wrapper = extendedWrapper(
      mount(ManageViaMr, {
        provide: {
          projectPath,
        },
        propsData: {
          feature: {
            name: featureName,
            type: featureType,
            configured: isFeatureConfigured,
          },
          variant,
          category,
        },
        ...options,
      }),
    );
  }

  afterEach(() => {
    wrapper.destroy();
  });

  // This component supports different report types/mutations depending on
  // whether it's in a CE or EE context. This makes sure we are only testing
  // the ones available in the current test context.
  const supportedReportTypes = Object.entries(featureToMutationMap).map(
    ([featureType, { getMutationPayload, mutationId }]) => {
      const { mutation, variables: mutationVariables } = getMutationPayload(projectPath);
      return [humanize(featureType), featureType, mutation, mutationId, mutationVariables];
    },
  );

  describe.each(supportedReportTypes)(
    '%s',
    (featureName, featureType, mutation, mutationId, mutationVariables) => {
      const buildConfigureSecurityFeatureMock = buildConfigureSecurityFeatureMockFactory(
        mutationId,
      );
      const successHandler = jest.fn(async () => buildConfigureSecurityFeatureMock());
      const noSuccessPathHandler = async () =>
        buildConfigureSecurityFeatureMock({
          successPath: '',
        });
      const errorHandler = async () =>
        buildConfigureSecurityFeatureMock({
          errors: ['foo'],
        });
      const pendingHandler = () => new Promise(() => {});

      describe('when feature is configured', () => {
        beforeEach(() => {
          const apolloProvider = createMockApolloProvider(mutation, successHandler);
          createComponent({ apolloProvider, featureName, featureType, isFeatureConfigured: true });
        });

        it('it does not render a button', () => {
          expect(findButton().exists()).toBe(false);
        });
      });

      describe('when feature is not configured', () => {
        beforeEach(() => {
          const apolloProvider = createMockApolloProvider(mutation, successHandler);
          createComponent({ apolloProvider, featureName, featureType, isFeatureConfigured: false });
        });

        it('it does render a button', () => {
          expect(findButton().exists()).toBe(true);
        });

        it('clicking on the button triggers the configure mutation', () => {
          findButton().trigger('click');

          expect(successHandler).toHaveBeenCalledTimes(1);
          expect(successHandler).toHaveBeenCalledWith(mutationVariables);
        });
      });

      describe('given a pending response', () => {
        beforeEach(() => {
          const apolloProvider = createMockApolloProvider(mutation, pendingHandler);
          createComponent({ apolloProvider, featureName, featureType });
        });

        it('renders spinner correctly', async () => {
          const button = findButton();
          expect(button.props('loading')).toBe(false);
          await button.trigger('click');
          expect(button.props('loading')).toBe(true);
        });
      });

      describe('given a successful response', () => {
        beforeEach(() => {
          const apolloProvider = createMockApolloProvider(mutation, successHandler);
          createComponent({ apolloProvider, featureName, featureType });
        });

        it('should call redirect helper with correct value', async () => {
          await wrapper.trigger('click');
          await waitForPromises();
          expect(redirectTo).toHaveBeenCalledTimes(1);
          expect(redirectTo).toHaveBeenCalledWith('testSuccessPath');
          // This is done for UX reasons. If the loading prop is set to false
          // on success, then there's a period where the button is clickable
          // again. Instead, we want the button to display a loading indicator
          // for the remainder of the lifetime of the page (i.e., until the
          // browser can start painting the new page it's been redirected to).
          expect(findButton().props().loading).toBe(true);
        });
      });

      describe.each`
        handler                 | message
        ${noSuccessPathHandler} | ${`${featureName} merge request creation mutation failed`}
        ${errorHandler}         | ${'foo'}
      `('given an error response', ({ handler, message }) => {
        beforeEach(() => {
          const apolloProvider = createMockApolloProvider(mutation, handler);
          createComponent({ apolloProvider, featureName, featureType });
        });

        it('should catch and emit error', async () => {
          await wrapper.trigger('click');
          await waitForPromises();
          expect(wrapper.emitted('error')).toEqual([[message]]);
          expect(findButton().props('loading')).toBe(false);
        });
      });
    },
  );

  describe('canRender static method', () => {
    it.each`
      context                                       | type                | available | configured | canEnableByMergeRequest | expectedValue
      ${'an unconfigured feature'}                  | ${REPORT_TYPE_SAST} | ${true}   | ${false}   | ${true}                 | ${true}
      ${'a configured feature'}                     | ${REPORT_TYPE_SAST} | ${true}   | ${true}    | ${true}                 | ${false}
      ${'an unavailable feature'}                   | ${REPORT_TYPE_SAST} | ${false}  | ${false}   | ${true}                 | ${false}
      ${'a feature which cannot be enabled via MR'} | ${REPORT_TYPE_SAST} | ${true}   | ${false}   | ${false}                | ${false}
      ${'an unknown feature'}                       | ${'foo'}            | ${true}   | ${false}   | ${true}                 | ${false}
    `(
      'given $context returns $expectedValue',
      ({ type, available, configured, canEnableByMergeRequest, expectedValue }) => {
        expect(
          ManageViaMr.canRender({
            type,
            available,
            configured,
            canEnableByMergeRequest,
          }),
        ).toBe(expectedValue);
      },
    );
  });

  describe('button props', () => {
    it('passes the variant and category props to the GlButton', () => {
      const variant = 'danger';
      const category = 'tertiary';
      createComponent({ variant, category });

      expect(wrapper.findComponent(GlButton).props()).toMatchObject({
        variant,
        category,
      });
    });
  });
});
