import { sortFindingsByFile } from '~/diffs/utils/sort_findings_by_file';

describe('sort_findings_by_file utilities', () => {
  const mockDescription = 'mockDescription';
  const mockSeverity = 'mockseverity';
  const mockLine = '00';
  const mockFile1 = 'file1.js';
  const mockFile2 = 'file2.rb';
  const webUrl1 = 'http://example.com/file1.js';
  const webUrl2 = 'http://example.com/file2.rb';
  const engineName1 = 'engineName1';
  const engineName2 = 'engineName2';
  const emptyResponse = {
    files: {},
  };

  const unsortedFindings = [
    {
      severity: mockSeverity,
      filePath: mockFile1,
      line: mockLine,
      description: mockDescription,
      webUrl: webUrl1,
      engineName: engineName1,
    },
    {
      severity: mockSeverity,
      filePath: mockFile2,
      line: mockLine,
      description: mockDescription,
      webUrl: webUrl2,
      engineName: engineName2,
    },
  ];
  const sortedFindings = {
    files: {
      [mockFile1]: [
        {
          line: mockLine,
          filePath: mockFile1,
          description: mockDescription,
          severity: mockSeverity,
          webUrl: webUrl1,
          engineName: engineName1,
        },
      ],
      [mockFile2]: [
        {
          line: mockLine,
          filePath: mockFile2,
          description: mockDescription,
          severity: mockSeverity,
          webUrl: webUrl2,
          engineName: engineName2,
        },
      ],
    },
  };

  it('sorts Findings correctly', () => {
    expect(sortFindingsByFile(unsortedFindings)).toEqual(sortedFindings);
  });
  it('does not throw error when given no input', () => {
    expect(sortFindingsByFile()).toEqual(emptyResponse);
  });
});
