import { sortFindingsByFile } from '~/diffs/utils/sort_findings_by_file';

describe('sort_findings_by_file utilities', () => {
  const mockDescription = 'mockDescription';
  const mockSeverity = 'mockseverity';
  const mockLine = '00';
  const mockFile1 = 'file1.js';
  const mockFile2 = 'file2.rb';
  const emptyResponse = {
    files: {},
  };

  const unsortedFindings = [
    {
      severity: mockSeverity,
      filePath: mockFile1,
      line: mockLine,
      description: mockDescription,
    },
    {
      severity: mockSeverity,
      filePath: mockFile2,
      line: mockLine,
      description: mockDescription,
    },
  ];
  const sortedFindings = {
    files: {
      [mockFile1]: [
        {
          line: mockLine,
          description: mockDescription,
          severity: mockSeverity,
        },
      ],
      [mockFile2]: [
        {
          line: mockLine,
          description: mockDescription,
          severity: mockSeverity,
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
