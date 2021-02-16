import { withKeys } from 'test_helpers/utils/obj';

export default (server) => {
  server.get('/api/v4/projects/:id', (schema, request) => {
    const { id } = request.params;

    const proj =
      schema.projects.findBy({ id }) ?? schema.projects.findBy({ path_with_namespace: id });

    return proj.attrs;
  });

  server.get('/api/v4/projects/:id/merge_requests', (schema, request) => {
    const result = schema.mergeRequests.where(
      withKeys(request.queryParams, {
        source_project_id: 'project_id',
        source_branch: 'source_branch',
      }),
    );

    return result.models;
  });

  server.get('/api/v4/projects/:id/merge_requests/:mid', (schema, request) => {
    const mr = schema.mergeRequests.findBy({ iid: request.params.mid });

    return mr.attrs;
  });

  server.get('/api/v4/projects/:id/merge_requests/:mid/versions', (schema, request) => {
    const versions = schema.mergeRequestVersions.where({ merge_request_id: request.params.mid });

    return versions.models;
  });

  server.get('/api/v4/projects/:id/merge_requests/:mid/changes', (schema, request) => {
    const mrWithChanges = schema.mergeRequestChanges.findBy({ iid: request.params.mid });

    return mrWithChanges.attrs;
  });
};
