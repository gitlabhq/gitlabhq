import Vue from 'vue';
import { GlAlert, GlEmptyState, GlLoadingIcon, GlPopover } from '@gitlab/ui';
import VueApollo from 'vue-apollo';

import mockCiLintMutationResponse from 'test_fixtures/graphql/ci/pipeline_editor/graphql/mutations/ci_lint.mutation.graphql.json';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { resolvers } from '~/ci/pipeline_editor/graphql/resolvers';
import CiLintResults from '~/ci/pipeline_editor/components/lint/ci_lint_results.vue';
import BranchSelector from '~/ci/pipeline_editor/components/shared/branch_selector.vue';
import CiValidate, { i18n } from '~/ci/pipeline_editor/components/validate/ci_validate.vue';
import ValidatePipelinePopover from '~/ci/pipeline_editor/components/popovers/validate_pipeline_popover.vue';
import getBlobContent from '~/ci/pipeline_editor/graphql/queries/blob_content.query.graphql';
import ciLintMutation from '~/ci/pipeline_editor/graphql/mutations/ci_lint.mutation.graphql';
import getCurrentBranch from '~/ci/pipeline_editor/graphql/queries/client/current_branch.query.graphql';
import { pipelineEditorTrackingOptions } from '~/ci/pipeline_editor/constants';
import {
  mockBlobContentQueryResponse,
  ciLintErrorResponse,
  mockCiLintPath,
  mockCiYml,
  mockCurrentBranchResponse,
  mockDefaultBranch,
  mockSimulatePipelineHelpPagePath,
} from '../../mock_data';
import { mockCiLintJobs } from '../../../ci_lint/mock_data';

Vue.use(VueApollo);

const defaultProvide = {
  ciConfigPath: '/path/to/ci-config',
  ciLintPath: mockCiLintPath,
  projectFullPath: '/path/to/project',
  validateTabIllustrationPath: '/path/to/img',
  simulatePipelineHelpPagePath: mockSimulatePipelineHelpPagePath,
};

describe('Pipeline Editor Validate Tab', () => {
  let wrapper;
  let mockBlobContentData;
  let mockCiLintData;
  let trackingSpy;

  const createComponent = ({ props, stubs } = {}) => {
    const handlers = [
      [getBlobContent, mockBlobContentData],
      [ciLintMutation, mockCiLintData],
    ];
    const mockApollo = createMockApollo(handlers, resolvers);

    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getCurrentBranch,
      data: mockCurrentBranchResponse,
    });

    wrapper = shallowMountExtended(CiValidate, {
      propsData: {
        ciFileContent: mockCiYml,
        ...props,
      },
      stubs,
      provide: {
        ...defaultProvide,
      },
      apolloProvider: mockApollo,
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findCancelBtn = () => wrapper.findByTestId('cancel-simulation');
  const findContentChangeStatus = () => wrapper.findByTestId('content-status');
  const findCta = () => wrapper.findByTestId('simulate-pipeline-button');
  const findLintButton = () => wrapper.findByTestId('lint-button');
  const findDisabledCtaTooltip = () => wrapper.findByTestId('cta-tooltip');
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findBranchSelector = () => wrapper.findComponent(BranchSelector);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findCiLintResults = () => wrapper.findComponent(CiLintResults);

  beforeEach(() => {
    mockBlobContentData = jest.fn();
    mockCiLintData = jest.fn();
  });

  describe('while initial CI content is loading', () => {
    beforeEach(() => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);

      createComponent();
    });

    it('renders disabled CTA with tooltip', () => {
      expect(findCta().props('disabled')).toBe(true);
      expect(findDisabledCtaTooltip().exists()).toBe(true);
    });
  });

  describe('after initial CI content is loaded', () => {
    beforeEach(async () => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      await createComponent({ stubs: { GlPopover, ValidatePipelinePopover } });
    });

    it('renders branch selector with the correct props', () => {
      expect(findBranchSelector().props()).toMatchObject({
        dropdownHeader: 'Select branch',
        currentBranchName: mockDefaultBranch,
      });
    });

    it('renders enabled CTA without tooltip', async () => {
      await waitForPromises();

      expect(findCta().exists()).toBe(true);
      expect(findCta().props('disabled')).toBe(false);
      expect(findDisabledCtaTooltip().exists()).toBe(false);
    });

    it('popover is set to render when hovering over help icon', () => {
      expect(findPopover().props('target')).toBe('validate-pipeline-help');
      expect(findPopover().props('container')).toBe('pipeline-source-selector');
      expect(findPopover().props('triggers')).toBe('hover focus');
    });

    it('renders lint button with correct path', () => {
      expect(findLintButton().exists()).toBe(true);
      expect(findLintButton().attributes('href')).toBe(mockCiLintPath);
    });
  });

  describe('simulating the pipeline', () => {
    beforeEach(async () => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      await createComponent();

      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
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
      await findCta().vm.$emit('click');

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findCancelBtn().exists()).toBe(true);
      expect(findCta().props('loading')).toBe(true);
    });

    it('calls ciLint mutation with the correct input', async () => {
      findCta().vm.$emit('click');

      await waitForPromises();

      expect(mockCiLintData).toHaveBeenCalledWith({
        projectPath: defaultProvide.projectFullPath,
        content: mockCiYml,
        ref: mockDefaultBranch,
        dryRun: true,
      });
    });

    describe('when another branch is selected', () => {
      const newBranch = 'new-branch';
      it('calls ciLint mutation with the selected branch', async () => {
        findBranchSelector().vm.$emit('select-branch', newBranch);
        findCta().vm.$emit('click');

        await waitForPromises();

        expect(mockCiLintData).toHaveBeenCalledWith({
          projectPath: defaultProvide.projectFullPath,
          content: mockCiYml,
          ref: newBranch,
          dryRun: true,
        });
      });
    });

    describe('when results are successful', () => {
      beforeEach(async () => {
        mockCiLintData.mockResolvedValue(mockCiLintMutationResponse);
        await createComponent();

        findCta().vm.$emit('click');
        await waitForPromises();
      });

      it('renders success alert', () => {
        expect(findAlert().exists()).toBe(true);
        expect(findAlert().attributes('variant')).toBe('success');
        expect(findAlert().attributes('title')).toBe(i18n.successAlertTitle);
      });

      it('does not render content change status', () => {
        expect(findContentChangeStatus().exists()).toBe(false);
      });

      it('renders CTA for results page', () => {
        expect(findCta().exists()).toBe(true);
      });

      it('renders CI lint results with correct props', () => {
        expect(findCiLintResults().exists()).toBe(true);
        expect(findCiLintResults().props()).toMatchObject({
          dryRun: true,
          hideAlert: true,
          isValid: true,
          jobs: mockCiLintJobs,
        });
      });
    });

    describe('when results have errors', () => {
      beforeEach(async () => {
        mockCiLintData.mockResolvedValue(ciLintErrorResponse);

        findCta().vm.$emit('click');

        await waitForPromises();
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
          errors: ciLintErrorResponse.data.ciLint.config.errors,
          warnings: ciLintErrorResponse.data.ciLint.config.warnings,
        });
      });
    });
  });

  describe('when CI content has changed after a simulation', () => {
    beforeEach(async () => {
      mockCiLintData.mockResolvedValue(mockCiLintMutationResponse);
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      await createComponent();

      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
      findCta().vm.$emit('click');
      await waitForPromises();
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
      findCta().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, resimulatePipeline, { label });
    });

    it('renders content change status', async () => {
      await wrapper.setProps({ ciFileContent: 'new yaml content' });

      expect(findContentChangeStatus().props('variant')).toBe('warning');
      expect(findContentChangeStatus().text()).toBe(
        'Configuration content has changed. Re-run validation for updated results.',
      );
      expect(findCta().exists()).toBe(true);
    });

    it('calls mutation with new content', async () => {
      const newContent = 'new yaml content';
      await wrapper.setProps({ ciFileContent: newContent });
      findCta().vm.$emit('click');

      await waitForPromises();

      expect(mockCiLintData).toHaveBeenCalledTimes(2);
      expect(mockCiLintData).toHaveBeenCalledWith({
        content: 'new yaml content',
        dryRun: true,
        projectPath: '/path/to/project',
        ref: mockDefaultBranch,
      });
    });
  });

  describe('canceling a simulation', () => {
    beforeEach(async () => {
      mockBlobContentData.mockResolvedValue(mockBlobContentQueryResponse);
      await createComponent();
    });

    it('returns to init state', async () => {
      // init state
      expect(findEmptyState().exists()).toBe(true);
      expect(findCiLintResults().exists()).toBe(false);

      // mutations should have successful results
      await findCta().vm.$emit('click');

      // cancel before simulation succeeds
      expect(findCancelBtn().exists()).toBe(true);
      await findCancelBtn().vm.$emit('click');

      // should still render init state
      expect(findEmptyState().exists()).toBe(true);
      expect(findCiLintResults().exists()).toBe(false);
    });
  });
});
