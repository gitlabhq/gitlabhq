import { GlAlert, GlDisclosureDropdown, GlIcon, GlLoadingIcon, GlPopover } from '@gitlab/ui';
import { nextTick } from 'vue';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import CiLintResults from '~/ci/pipeline_editor/components/lint/ci_lint_results.vue';
import CiValidate, { i18n } from '~/ci/pipeline_editor/components/validate/ci_validate.vue';
import ValidatePipelinePopover from '~/ci/pipeline_editor/components/popovers/validate_pipeline_popover.vue';
import getBlobContent from '~/ci/pipeline_editor/graphql/queries/blob_content.query.graphql';
import lintCIMutation from '~/ci/pipeline_editor/graphql/mutations/client/lint_ci.mutation.graphql';
import { pipelineEditorTrackingOptions } from '~/ci/pipeline_editor/constants';
import {
  mockBlobContentQueryResponse,
  mockCiLintPath,
  mockCiYml,
  mockSimulatePipelineHelpPagePath,
} from '../../mock_data';
import { mockLintDataError, mockLintDataValid } from '../../../ci_lint/mock_data';

const localVue = createLocalVue();
localVue.use(VueApollo);

describe('Pipeline Editor Validate Tab', () => {
  let wrapper;
  let mockApollo;
  let mockBlobContentData;
  let trackingSpy;

  const createComponent = ({
    props,
    stubs,
    options,
    isBlobLoading = false,
    isSimulationLoading = false,
  } = {}) => {
    wrapper = shallowMountExtended(CiValidate, {
      propsData: {
        ciFileContent: mockCiYml,
        ...props,
      },
      provide: {
        ciConfigPath: '/path/to/ci-config',
        ciLintPath: mockCiLintPath,
        currentBranch: 'main',
        projectFullPath: '/path/to/project',
        validateTabIllustrationPath: '/path/to/img',
        simulatePipelineHelpPagePath: mockSimulatePipelineHelpPagePath,
      },
      stubs,
      mocks: {
        $apollo: {
          queries: {
            initialBlobContent: {
              loading: isBlobLoading,
            },
          },
          mutations: {
            lintCiMutation: {
              loading: isSimulationLoading,
            },
          },
        },
      },
      ...options,
    });
  };

  const createComponentWithApollo = ({ props, stubs } = {}) => {
    const handlers = [[getBlobContent, mockBlobContentData]];
    mockApollo = createMockApollo(handlers);

    createComponent({
      props,
      stubs,
      options: {
        localVue,
        apolloProvider: mockApollo,
        mocks: {},
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findCancelBtn = () => wrapper.findByTestId('cancel-simulation');
  const findContentChangeStatus = () => wrapper.findByTestId('content-status');
  const findCta = () => wrapper.findByTestId('simulate-pipeline-button');
  const findDisabledCtaTooltip = () => wrapper.findByTestId('cta-tooltip');
  const findHelpIcon = () => wrapper.findComponent(GlIcon);
  const findIllustration = () => wrapper.findByRole('img');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPipelineSource = () => wrapper.findComponent(GlDisclosureDropdown);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findCiLintResults = () => wrapper.findComponent(CiLintResults);
  const findResultsCta = () => wrapper.findByTestId('resimulate-pipeline-button');

  beforeEach(() => {
    mockBlobContentData = jest.fn();
  });

  describe('while initial CI content is loading', () => {
    beforeEach(() => {
      createComponent({ isBlobLoading: true });
    });

    it('renders disabled CTA with tooltip', () => {
      expect(findCta().props('disabled')).toBe(true);
      expect(findDisabledCtaTooltip().exists()).toBe(true);
    });
  });

  describe('after initial CI content is loaded', () => {
    beforeEach(async () => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      await createComponentWithApollo({ stubs: { GlPopover, ValidatePipelinePopover } });
    });

    it('renders disabled pipeline source dropdown', () => {
      expect(findPipelineSource().exists()).toBe(true);
      expect(findPipelineSource().attributes('toggletext')).toBe(i18n.pipelineSourceDefault);
      expect(findPipelineSource().props('disabled')).toBe(true);
    });

    it('renders enabled CTA without tooltip', () => {
      expect(findCta().exists()).toBe(true);
      expect(findCta().props('disabled')).toBe(false);
      expect(findDisabledCtaTooltip().exists()).toBe(false);
    });

    it('popover is set to render when hovering over help icon', () => {
      expect(findPopover().props('target')).toBe(findHelpIcon().attributes('id'));
      expect(findPopover().props('triggers')).toBe('hover focus');
    });
  });

  describe('simulating the pipeline', () => {
    beforeEach(async () => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      await createComponentWithApollo();

      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockLintDataValid);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('tracks the simulation event', () => {
      const {
        label,
        actions: { simulatePipeline },
      } = pipelineEditorTrackingOptions;
      findCta().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, simulatePipeline, { label });
    });

    it('renders loading state while simulation is ongoing', async () => {
      findCta().vm.$emit('click');
      await nextTick();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findCancelBtn().exists()).toBe(true);
      expect(findCta().props('loading')).toBe(true);
    });

    it('calls mutation with the correct input', async () => {
      await findCta().vm.$emit('click');

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledTimes(1);
      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: lintCIMutation,
        variables: {
          dry: true,
          content: mockCiYml,
          endpoint: mockCiLintPath,
        },
      });
    });

    describe('when results are successful', () => {
      beforeEach(async () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockLintDataValid);
        await findCta().vm.$emit('click');
      });

      it('renders success alert', () => {
        expect(findAlert().exists()).toBe(true);
        expect(findAlert().attributes('variant')).toBe('success');
        expect(findAlert().attributes('title')).toBe(i18n.successAlertTitle);
      });

      it('does not render content change status or CTA for results page', () => {
        expect(findContentChangeStatus().exists()).toBe(false);
        expect(findResultsCta().exists()).toBe(false);
      });

      it('renders CI lint results with correct props', () => {
        expect(findCiLintResults().exists()).toBe(true);
        expect(findCiLintResults().props()).toMatchObject({
          dryRun: true,
          hideAlert: true,
          isValid: true,
          jobs: mockLintDataValid.data.lintCI.jobs,
        });
      });
    });

    describe('when results have errors', () => {
      beforeEach(async () => {
        jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockLintDataError);
        await findCta().vm.$emit('click');
      });

      it('renders error alert', () => {
        expect(findAlert().exists()).toBe(true);
        expect(findAlert().attributes('variant')).toBe('danger');
        expect(findAlert().attributes('title')).toBe(i18n.errorAlertTitle);
      });

      it('renders CI lint results with correct props', () => {
        expect(findCiLintResults().exists()).toBe(true);
        expect(findCiLintResults().props()).toMatchObject({
          dryRun: true,
          hideAlert: true,
          isValid: false,
          errors: mockLintDataError.data.lintCI.errors,
          warnings: mockLintDataError.data.lintCI.warnings,
        });
      });
    });
  });

  describe('when CI content has changed after a simulation', () => {
    beforeEach(async () => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      await createComponentWithApollo();

      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockLintDataValid);
      await findCta().vm.$emit('click');
    });

    afterEach(() => {
      unmockTracking();
    });

    it('tracks the second simulation event', async () => {
      const {
        label,
        actions: { resimulatePipeline },
      } = pipelineEditorTrackingOptions;

      await wrapper.setProps({ ciFileContent: 'new yaml content' });
      findResultsCta().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, resimulatePipeline, { label });
    });

    it('renders content change status', async () => {
      await wrapper.setProps({ ciFileContent: 'new yaml content' });

      expect(findContentChangeStatus().exists()).toBe(true);
      expect(findResultsCta().exists()).toBe(true);
    });

    it('calls mutation with new content', async () => {
      await wrapper.setProps({ ciFileContent: 'new yaml content' });
      await findResultsCta().vm.$emit('click');

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledTimes(2);
      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: lintCIMutation,
        variables: {
          dry: true,
          content: 'new yaml content',
          endpoint: mockCiLintPath,
        },
      });
    });
  });

  describe('canceling a simulation', () => {
    beforeEach(async () => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      await createComponentWithApollo();
    });

    it('returns to init state', async () => {
      // init state
      expect(findIllustration().exists()).toBe(true);
      expect(findCiLintResults().exists()).toBe(false);

      // mutations should have successful results
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockLintDataValid);
      findCta().vm.$emit('click');
      await nextTick();

      // cancel before simulation succeeds
      expect(findCancelBtn().exists()).toBe(true);
      await findCancelBtn().vm.$emit('click');

      // should still render init state
      expect(findIllustration().exists()).toBe(true);
      expect(findCiLintResults().exists()).toBe(false);
    });
  });
});
