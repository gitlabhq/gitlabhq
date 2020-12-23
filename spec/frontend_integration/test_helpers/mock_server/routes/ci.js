import { getPipelinesEmptyResponse } from 'test_helpers/fixtures';

export default (server) => {
  server.get('*/commit/:id/pipelines', () => {
    return getPipelinesEmptyResponse();
  });

  server.get('/api/v4/projects/:id/runners', () => {
    return [];
  });
};
