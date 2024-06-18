import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PagesPipelineWizard, { i18n } from '~/gitlab_pages/components/pages_pipeline_wizard.vue';
import PipelineWizard from '~/pipeline_wizard/pipeline_wizard.vue';
import pagesTemplate from '~/pipeline_wizard/templates/pages.yml';
import pagesMarkOnboardingComplete from '~/gitlab_pages/queries/mark_onboarding_complete.graphql';
import { visitUrl } from '~/lib/utils/url_utility';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility');

describe('PagesPipelineWizard', () => {
  const markOnboardingCompleteMutationHandler = jest.fn();
  let wrapper;
  const props = {
    projectPath: '/user/repo',
    defaultBranch: 'main',
    redirectToWhenDone: './',
  };

  const findPipelineWizardWrapper = () => wrapper.findComponent(PipelineWizard);
  const createMockApolloProvider = () => {
    return createMockApollo([
      [
        pagesMarkOnboardingComplete,
        markOnboardingCompleteMutationHandler.mockResolvedValue({
          data: {
            pagesMarkOnboardingComplete: {
              onboardingComplete: true,
              errors: [],
            },
          },
        }),
      ],
    ]);
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(PagesPipelineWizard, {
      apolloProvider: createMockApolloProvider(),
      propsData: props,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('shows the pipeline wizard', () => {
    expect(findPipelineWizardWrapper().exists()).toBe(true);
  });

  it('passes the appropriate props', () => {
    const pipelineWizardWrapperProps = findPipelineWizardWrapper().props();

    expect(pipelineWizardWrapperProps.template).toBe(pagesTemplate);
    expect(pipelineWizardWrapperProps.projectPath).toBe(props.projectPath);
    expect(pipelineWizardWrapperProps.defaultBranch).toBe(props.defaultBranch);
  });

  describe('after the steps are complete', () => {
    const mockDone = () => findPipelineWizardWrapper().vm.$emit('done');

    it('shows a loading screen during the update', async () => {
      mockDone();

      await nextTick();

      const loadingScreenWrapper = wrapper.findByTestId('onboarding-mutation-loading');
      expect(loadingScreenWrapper.exists()).toBe(true);
      expect(loadingScreenWrapper.text()).toBe(i18n.loadingMessage);
    });

    it('calls pagesMarkOnboardingComplete mutation when done', async () => {
      mockDone();

      await waitForPromises();

      expect(markOnboardingCompleteMutationHandler).toHaveBeenCalledWith({
        input: {
          projectPath: props.projectPath,
        },
      });
    });

    it('navigates to the path defined in redirectToWhenDone when done', async () => {
      mockDone();

      await waitForPromises();

      expect(visitUrl).toHaveBeenCalledWith(props.redirectToWhenDone);
    });
  });
});
