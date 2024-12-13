import Vue from 'vue';
import { GlAlert, GlDisclosureDropdown, GlEmptyState, GlLoadingIcon, GlPopover } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import MockAdapter from 'axios-mock-adapter';

import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { resolvers } from '~/ci/pipeline_editor/graphql/resolvers';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import CiLintResults from '~/ci/pipeline_editor/components/lint/ci_lint_results.vue';
import CiValidate, { i18n } from '~/ci/pipeline_editor/components/validate/ci_validate.vue';
import ValidatePipelinePopover from '~/ci/pipeline_editor/components/popovers/validate_pipeline_popover.vue';
import getBlobContent from '~/ci/pipeline_editor/graphql/queries/blob_content.query.graphql';
import { pipelineEditorTrackingOptions } from '~/ci/pipeline_editor/constants';
import {
  mockBlobContentQueryResponse,
  mockCiLintPath,
  mockCiYml,
  mockSimulatePipelineHelpPagePath,
} from '../../mock_data';
import {
  mockLintDataError,
  mockLintDataValid,
  mockLintDataErrorRest,
  mockLintDataValidRest,
} from '../../../ci_lint/mock_data';

let mockAxios;

Vue.use(VueApollo);

const defaultProvide = {
  ciConfigPath: '/path/to/ci-config',
  ciLintPath: mockCiLintPath,
  currentBranch: 'main',
  projectFullPath: '/path/to/project',
  validateTabIllustrationPath: '/path/to/img',
  simulatePipelineHelpPagePath: mockSimulatePipelineHelpPagePath,
};

describe('Pipeline Editor Validate Tab', () => {
  let wrapper;
  let mockBlobContentData;
  let trackingSpy;

  const createComponent = ({ props, stubs } = {}) => {
    const handlers = [[getBlobContent, mockBlobContentData]];
    const mockApollo = createMockApollo(handlers, resolvers);

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
  const findHelpIcon = () => wrapper.findComponent(HelpIcon);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPipelineSource = () => wrapper.findComponent(GlDisclosureDropdown);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findCiLintResults = () => wrapper.findComponent(CiLintResults);
  const findResultsCta = () => wrapper.findByTestId('resimulate-pipeline-button');

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    mockAxios.onPost(defaultProvide.ciLintPath).reply(HTTP_STATUS_OK, mockLintDataValidRest);

    mockBlobContentData = jest.fn();
  });

  afterEach(() => {
    mockAxios.restore();
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

    it('calls endpoint with the correct input', async () => {
      findCta().vm.$emit('click');

      await waitForPromises();

      expect(mockAxios.history.post).toHaveLength(1);
      expect(mockAxios.history.post[0].data).toBe(
        JSON.stringify({
          content: mockCiYml,
          dry_run: true,
        }),
      );
    });

    describe('when results are successful', () => {
      beforeEach(async () => {
        findCta().vm.$emit('click');

        await waitForPromises();
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
        mockAxios.onPost(defaultProvide.ciLintPath).reply(HTTP_STATUS_OK, mockLintDataErrorRest);
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
          errors: mockLintDataError.data.lintCI.errors,
          warnings: mockLintDataError.data.lintCI.warnings,
        });
      });
    });
  });

  describe('when CI content has changed after a simulation', () => {
    beforeEach(async () => {
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
      findResultsCta().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, resimulatePipeline, { label });
    });

    it('renders content change status', async () => {
      await wrapper.setProps({ ciFileContent: 'new yaml content' });

      expect(findContentChangeStatus().exists()).toBe(true);
      expect(findResultsCta().exists()).toBe(true);
    });

    it('calls mutation with new content', async () => {
      const newContent = 'new yaml content';
      await wrapper.setProps({ ciFileContent: newContent });
      findResultsCta().vm.$emit('click');

      await waitForPromises();

      expect(mockAxios.history.post).toHaveLength(2);
      expect(mockAxios.history.post[1].data).toBe(
        JSON.stringify({
          content: newContent,
          dry_run: true,
        }),
      );
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
