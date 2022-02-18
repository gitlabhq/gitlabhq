const randomWarning = {
  content: 'another random warning',
  id: 'gid://gitlab/Ci::PipelineMessage/272',
};

const rootTypeWarning = {
  content: 'root `types` will be removed in 15.0.',
  id: 'gid://gitlab/Ci::PipelineMessage/273',
};

const typeWarning = {
  content: '`type` will be removed in 15.0.',
  id: 'gid://gitlab/Ci::PipelineMessage/274',
};

function createWarningMock(warnings) {
  return {
    data: {
      project: {
        id: 'gid://gitlab/Project/28"',
        pipeline: {
          id: 'gid://gitlab/Ci::Pipeline/183',
          warningMessages: warnings,
        },
      },
    },
  };
}

export const mockWarningsWithoutDeprecation = createWarningMock([randomWarning]);
export const mockWarningsRootType = createWarningMock([rootTypeWarning]);
export const mockWarningsType = createWarningMock([typeWarning]);
export const mockWarningsTypesAll = createWarningMock([rootTypeWarning, typeWarning]);
