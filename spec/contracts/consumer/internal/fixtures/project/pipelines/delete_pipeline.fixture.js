const DeletePipeline = {
  success: {
    status: 200,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
    },
  },

  scenario: {
    state: 'a pipeline for a project exists',
    uponReceiving: 'a request to delete the pipeline',
  },

  request: {
    method: 'POST',
    path: '/api/graphql',
  },

  variables: {
    id: 'gid://gitlab/Ci::Pipeline/316112',
  },
};

export { DeletePipeline };
