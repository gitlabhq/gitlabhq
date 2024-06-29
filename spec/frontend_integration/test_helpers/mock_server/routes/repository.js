import { createNewCommit, createCommitIdGenerator } from 'test_helpers/factories';

export default (server) => {
  const commitIdGenerator = createCommitIdGenerator();

  server.get('/api/v4/projects/:id/repository/branches', (schema) => {
    return schema.db.branches;
  });

  server.get('/api/v4/projects/:id/repository/branches/:name', (schema, request) => {
    const { name } = request.params;

    const branch = schema.branches.findBy({ name });

    return branch.attrs;
  });

  server.get('*/-/files/:id', (schema) => {
    return schema.db.files.map(({ path }) => path);
  });

  server.get('/:namespace/:project/-/blob/:sha/*path', (schema, request) => {
    const { path } = schema.db.files.findBy({ path: request.params.path });

    return { path, rawPath: request.url.replace('/-/blob', '/-/raw') };
  });

  server.get('/:namespace/:project/-/raw/:sha/*path', (schema, request) => {
    const { path } = request.params;

    return schema.db.filesRaw.findBy({ path })?.raw || 'Sample content';
  });

  server.post('/api/v4/projects/:id/repository/commits', (schema, request) => {
    const {
      branch: branchName,
      commit_message: message,
      actions,
    } = JSON.parse(request.requestBody);

    const branch = schema.branches.findBy({ name: branchName });
    const prevCommit = branch
      ? branch.attrs.commit
      : schema.branches.findBy({ name: 'master' }).attrs.commit;

    const commit = {
      ...createNewCommit({ id: commitIdGenerator.next(), message }, prevCommit),
      __actions: actions,
    };

    if (branch) {
      branch.update({ commit });
    } else {
      schema.branches.create({
        name: branchName,
        commit,
      });
    }

    return commit;
  });
};
