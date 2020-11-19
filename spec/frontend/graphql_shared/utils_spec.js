import { getIdFromGraphQLId } from '~/graphql_shared/utils';

describe('getIdFromGraphQLId', () => {
  [
    {
      input: '',
      output: null,
    },
    {
      input: null,
      output: null,
    },
    {
      input: 2,
      output: 2,
    },
    {
      input: 'gid://',
      output: null,
    },
    {
      input: 'gid://gitlab/',
      output: null,
    },
    {
      input: 'gid://gitlab/Environments',
      output: null,
    },
    {
      input: 'gid://gitlab/Environments/',
      output: null,
    },
    {
      input: 'gid://gitlab/Environments/123',
      output: 123,
    },
    {
      input: 'gid://gitlab/DesignManagement::Version/2',
      output: 2,
    },
  ].forEach(({ input, output }) => {
    it(`getIdFromGraphQLId returns ${output} when passed ${input}`, () => {
      expect(getIdFromGraphQLId(input)).toBe(output);
    });
  });
});
