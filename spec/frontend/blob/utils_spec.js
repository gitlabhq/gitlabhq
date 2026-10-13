import * as utils from '~/blob/utils';

describe('Blob utilities', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    document.body.innerHTML = '';
  });

  describe('isMarkdownFilePath', () => {
    it.each`
      path           | result
      ${'README.md'} | ${true}
      ${'README.MD'} | ${true}
      ${'markdown'}  | ${false}
      ${'file.rb'}   | ${false}
      ${undefined}   | ${false}
    `('returns $result for $path', ({ path, result }) => {
      expect(utils.isMarkdownFilePath(path)).toBe(result);
    });
  });
});
