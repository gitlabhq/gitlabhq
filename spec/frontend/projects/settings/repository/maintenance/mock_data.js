export const TEST_HEADER_HEIGHT = '123px';
export const TEST_PROJECT_PATH = 'project/path';
export const TEST_BLOB_ID = '96803162678c7c1ff1e130424b95f28f84ec99cf';
export const TEST_TEXT = 'some text';

export const REMOVE_MUTATION_SUCCESS = {
  data: {
    projectBlobsRemove: {
      errors: [],
      __typename: 'projectBlobsRemovePayload',
    },
  },
};

export const REMOVE_MUTATION_FAIL = {
  data: {
    projectBlobsRemove: {
      errors: ['Some error'],
      __typename: 'projectBlobsRemovePayload',
    },
  },
};

export const REPLACE_MUTATION_SUCCESS = {
  data: {
    projectTextReplace: {
      errors: [],
      __typename: 'projectTextReplacePayload',
    },
  },
};

export const REPLACE_MUTATION_FAIL = {
  data: {
    projectTextReplace: {
      errors: ['Some error'],
      __typename: 'projectTextReplacePayload',
    },
  },
};
