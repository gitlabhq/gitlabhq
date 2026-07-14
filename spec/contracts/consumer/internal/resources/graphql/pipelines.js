import axios from 'axios';

import { extractGraphQLQuery } from '../../helpers/graphql_query_extractor';

export async function getPipelineHeaderDataRequest(endpoint) {
  const { url } = endpoint;
  const query = await extractGraphQLQuery(
    'app/assets/javascripts/ci/pipeline_details/header/graphql/queries/get_pipeline_header_data.query.graphql',
  );
  const graphqlQuery = {
    query,
    variables: {
      fullPath: 'gitlab-org/gitlab-qa',
      iid: 1,
    },
  };

  return axios({
    method: 'POST',
    baseURL: url,
    url: '/api/graphql',
    headers: { Accept: '*/*' },
    data: graphqlQuery,
  });
}

export async function deletePipeline(endpoint) {
  const { url } = endpoint;
  const query = await extractGraphQLQuery(
    'app/assets/javascripts/ci/pipeline_details/graphql/mutations/delete_pipeline.mutation.graphql',
  );
  const graphqlQuery = {
    query,
    variables: {
      id: 'gid://gitlab/Ci::Pipeline/316112',
    },
  };

  return axios({
    baseURL: url,
    url: '/api/graphql',
    method: 'POST',
    headers: { Accept: '*/*' },
    data: graphqlQuery,
  });
}
