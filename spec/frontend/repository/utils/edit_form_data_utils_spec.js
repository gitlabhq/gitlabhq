import {
  prepareEditFormData,
  prepareCreateFormData,
} from '~/repository/utils/edit_form_data_utils';

describe('edit_form_data_utils', () => {
  let formData;

  beforeEach(() => {
    formData = new FormData();
  });

  describe('prepareEditFormData', () => {
    const params = {
      fileContent: 'console.log("Hello World");',
      filePath: 'src/test.js',
      lastCommitSha: 'abc123def456',
      fromMergeRequestIid: '42',
    };

    it('appends all required fields to FormData and returns plain object', () => {
      const result = prepareEditFormData(formData, params);

      expect(result).toEqual({
        file: params.fileContent,
        file_path: params.filePath,
        last_commit_sha: params.lastCommitSha,
        from_merge_request_iid: params.fromMergeRequestIid,
      });
    });
  });

  describe('prepareCreateFormData', () => {
    const params = {
      filePath: 'new-file.md',
      fileContent: '# New File\n\nThis is a new file.',
    };

    it('appends file_name and content to FormData and returns plain object', () => {
      const result = prepareCreateFormData(formData, params);

      expect(result).toEqual({
        file_name: params.filePath,
        content: params.fileContent,
      });
    });

    it('handles empty file content', () => {
      const emptyParams = { ...params, fileContent: '' };
      const result = prepareCreateFormData(formData, emptyParams);

      expect(result).toEqual({
        file_name: params.filePath,
        content: '',
      });
    });

    it('handles file paths with special characters', () => {
      const specialParams = {
        ...params,
        filePath: 'docs/special file (with spaces & symbols).txt',
      };
      const result = prepareCreateFormData(formData, specialParams);

      expect(result.file_name).toBe(specialParams.filePath);
    });

    it('handles multiline content with different line endings', () => {
      const multilineParams = {
        ...params,
        fileContent: 'Line 1\nLine 2\r\nLine 3\rLine 4',
      };
      const result = prepareCreateFormData(formData, multilineParams);

      expect(result.content).toBe(multilineParams.fileContent);
    });
  });
});
