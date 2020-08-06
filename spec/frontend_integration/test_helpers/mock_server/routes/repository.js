import { createNewCommit, createCommitIdGenerator } from 'test_helpers/factories';

export default server => {
  const commitIdGenerator = createCommitIdGenerator();

  server.get('/api/v4/projects/:id/repository/branches', schema => {
    return schema.db.branches;
  });

  server.get('/api/v4/projects/:id/repository/branches/:name', (schema, request) => {
    const { name } = request.params;

    const branch = schema.branches.findBy({ name });

    return branch.attrs;
  });

  server.get('*/-/files/:id', schema => {
    return schema.db.files.map(({ path }) => path);
  });

  server.post('/api/v4/projects/:id/repository/commits', (schema, request) => {
    const { branch: branchName, commit_message: message, actions } = JSON.parse(
      request.requestBody,
    );

    const branch = schema.branches.findBy({ name: branchName });

    const commit = {
      ...createNewCommit({ id: commitIdGenerator.next(), message }, branch.attrs.commit),
      __actions: actions,
    };

    branch.update({ commit });

    return commit;
  });
};
