import { pactWith } from 'jest-pact';
import { GraphQLInteraction } from '@pact-foundation/pact';

import { extractGraphQLQuery } from '../../../helpers/graphql_query_extractor';

import { PipelineHeaderData } from '../../../fixtures/project/pipelines/get_pipeline_header_data.fixture';
import { DeletePipeline } from '../../../fixtures/project/pipelines/delete_pipeline.fixture';

import { getPipelineHeaderDataRequest, deletePipeline } from '../../../resources/graphql/pipelines';

const CONSUMER_NAME = 'Pipelines#show';
const CONSUMER_LOG = '../logs/consumer.log';
const CONTRACT_DIR = '../contracts/project/pipelines/show';
const GET_PIPELINE_HEADER_DATA_PROVIDER_NAME = 'GET pipeline header data';
const DELETE_PIPELINE_PROVIDER_NAME = 'DELETE pipeline';

// GraphQL query: getPipelineHeaderData
pactWith(
  {
    consumer: CONSUMER_NAME,
    provider: GET_PIPELINE_HEADER_DATA_PROVIDER_NAME,
    log: CONSUMER_LOG,
    dir: CONTRACT_DIR,
  },

  (provider) => {
    describe(GET_PIPELINE_HEADER_DATA_PROVIDER_NAME, () => {
      beforeEach(async () => {
        const query = await extractGraphQLQuery(
          'app/assets/javascripts/ci/pipeline_details/header/graphql/queries/get_pipeline_header_data.query.graphql',
        );
        const graphqlQuery = new GraphQLInteraction()
          .given(PipelineHeaderData.scenario.state)
          .uponReceiving(PipelineHeaderData.scenario.uponReceiving)
          .withQuery(query)
          .withRequest(PipelineHeaderData.request)
          .withVariables(PipelineHeaderData.variables)
          .willRespondWith(PipelineHeaderData.success);

        provider.addInteraction(graphqlQuery);
      });

      it('returns a successful body', async () => {
        const pipelineHeaderData = await getPipelineHeaderDataRequest({
          url: provider.mockService.baseUrl,
        });

        expect(pipelineHeaderData.data).toEqual(PipelineHeaderData.body);
      });
    });
  },
);

// GraphQL query: deletePipeline
pactWith(
  {
    consumer: CONSUMER_NAME,
    provider: DELETE_PIPELINE_PROVIDER_NAME,
    log: CONSUMER_LOG,
    dir: CONTRACT_DIR,
  },

  (provider) => {
    describe(DELETE_PIPELINE_PROVIDER_NAME, () => {
      beforeEach(async () => {
        const query = await extractGraphQLQuery(
          'app/assets/javascripts/ci/pipeline_details/graphql/mutations/delete_pipeline.mutation.graphql',
        );
        const graphqlQuery = new GraphQLInteraction()
          .given(DeletePipeline.scenario.state)
          .uponReceiving(DeletePipeline.scenario.uponReceiving)
          .withQuery(query)
          .withRequest(DeletePipeline.request)
          .withVariables(DeletePipeline.variables)
          .willRespondWith(DeletePipeline.success);

        provider.addInteraction(graphqlQuery);
      });

      it('returns a successful body', async () => {
        const deletePipelineResponse = await deletePipeline({
          url: provider.mockService.baseUrl,
        });

        expect(deletePipelineResponse.status).toEqual(DeletePipeline.success.status);
      });
    });
  },
);
