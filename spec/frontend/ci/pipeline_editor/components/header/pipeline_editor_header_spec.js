import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMount } from '@vue/test-utils';
import { GlCard, GlLoadingIcon } from '@gitlab/ui';
import mockPipelineIidQueryResponse from 'test_fixtures/graphql/pipelines/get_pipeline_iid.query.graphql.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PipelineEditorHeader from '~/ci/pipeline_editor/components/header/pipeline_editor_header.vue';
import PipelineSummary from '~/ci/common/pipeline_summary/pipeline_summary.vue';
import ValidationSegment from '~/ci/pipeline_editor/components/header/validation_segment.vue';
import getPipelineIidQuery from '~/ci/pipeline_editor/graphql/queries/get_pipeline_iid.query.graphql';
import getPipelineEtagQuery from '~/ci/pipeline_editor/graphql/queries/client/pipeline_etag.query.graphql';

import { mockLintResponse } from '../../mock_data';

Vue.use(VueApollo);

describe('Pipeline editor header', () => {
  let wrapper;
  const pipelineIidHandler = jest.fn().mockResolvedValue(mockPipelineIidQueryResponse);

  const {
    data: {
      project: { pipeline },
    },
  } = mockPipelineIidQueryResponse;

  const defaultProps = {
    ciConfigData: mockLintResponse,
    commitSha: 'befcc427239b2e6206097b10639f7c95a86a84cf',
    isNewCiConfigFile: false,
  };

  const defaultProvide = {
    projectFullPath: '/full/path',
  };

  const createComponent = ({ provide = {}, props = {} } = {}) => {
    const handlers = [[getPipelineIidQuery, pipelineIidHandler]];
    const mockApollo = createMockApollo(handlers);
    mockApollo.clients.defaultClient.cache.writeQuery({
      query: getPipelineEtagQuery,
      data: {
        etags: {
          __typename: 'EtagValues',
          pipeline: 'pipelines/1',
        },
      },
    });

    wrapper = shallowMount(PipelineEditorHeader, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
      propsData: {
        ...defaultProps,
        ...props,
      },
      apolloProvider: mockApollo,
      stubs: {
        GlCard,
      },
    });

    return waitForPromises();
  };

  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPipelineSummary = () => wrapper.findComponent(PipelineSummary);
  const findValidationSegment = () => wrapper.findComponent(ValidationSegment);

  describe('loaded', () => {
    it('renders the validation segment', () => {
      createComponent();

      expect(findValidationSegment().exists()).toBe(true);
    });

    describe('pipeline summary', () => {
      it('hides the pipeline summary for new projects without a CI file', () => {
        createComponent({ props: { isNewCiConfigFile: true } });

        expect(findPipelineSummary().exists()).toBe(false);
      });

      it('renders the pipeline summary when CI file exists', async () => {
        pipelineIidHandler.mockResolvedValue(mockPipelineIidQueryResponse);
        await createComponent();

        expect(findPipelineSummary().exists()).toBe(true);
      });

      it('sends the correct props to the pipeline summary', async () => {
        pipelineIidHandler.mockResolvedValue(mockPipelineIidQueryResponse);
        await createComponent();

        expect(findPipelineSummary().props()).toMatchObject({
          fullPath: defaultProvide.projectFullPath,
          iid: pipeline.iid,
          includeCommitInfo: true,
          pipelineEtag: 'pipelines/1',
        });
      });
    });

    describe('polling', () => {
      describe('with pipeline id', () => {
        it('does not poll if pipeline has an id', async () => {
          pipelineIidHandler.mockResolvedValue(mockPipelineIidQueryResponse);
          await createComponent();

          expect(pipelineIidHandler).toHaveBeenCalledTimes(1);

          jest.advanceTimersByTime(5000);

          expect(pipelineIidHandler).toHaveBeenCalledTimes(1);
        });
      });

      describe('with no pipeline id', () => {
        beforeEach(async () => {
          mockPipelineIidQueryResponse.data.project.pipeline = null;
          pipelineIidHandler.mockResolvedValue(mockPipelineIidQueryResponse);
          await createComponent();
        });

        it('polls for pipeline', () => {
          expect(pipelineIidHandler).toHaveBeenCalledTimes(1);

          jest.advanceTimersByTime(5000);

          expect(pipelineIidHandler).toHaveBeenCalledTimes(2);
        });

        it('renders the loading icon', () => {
          expect(findLoadingIcon().exists()).toBe(true);
        });
      });
    });
  });
});
