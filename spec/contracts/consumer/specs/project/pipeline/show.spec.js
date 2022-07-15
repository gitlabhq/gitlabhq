/* eslint-disable @gitlab/require-i18n-strings */

import { pactWith } from 'jest-pact';
import { GraphQLInteraction } from '@pact-foundation/pact';

import { extractGraphQLQuery } from '../../../helpers/graphql_query_extractor';

import { PipelineHeaderData } from '../../../fixtures/project/pipeline/get_pipeline_header_data.fixture';
import { getPipelineHeaderDataRequest } from '../../../resources/graphql/pipelines';

const CONSUMER_NAME = 'Pipelines#show';
const CONSUMER_LOG = '../logs/consumer.log';
const CONTRACT_DIR = '../contracts/project/pipeline/show';
const PROVIDER_NAME = 'GET pipeline header data';

// GraphQL query: getPipelineHeaderData
pactWith(
  {
    consumer: CONSUMER_NAME,
    provider: PROVIDER_NAME,
    log: CONSUMER_LOG,
    dir: CONTRACT_DIR,
  },

  (provider) => {
    describe(PROVIDER_NAME, () => {
      beforeEach(async () => {
        const query = await extractGraphQLQuery(
          'app/assets/javascripts/pipelines/graphql/queries/get_pipeline_header_data.query.graphql',
        );
        const graphqlQuery = new GraphQLInteraction()
          .given('a pipeline for a project exists')
          .uponReceiving('a request for the pipeline header data')
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

/* eslint-enable @gitlab/require-i18n-strings */
