import {
  prepareEditFormData,
  prepareCreateFormData,
  prepareDataForApiEdit,
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

  describe('prepareDataForApiEdit', () => {
    it('returns branch and commit_message when branch_name is not provided', () => {
      const originalFormData = {
        original_branch: 'main',
        commit_message: 'Update file content',
      };

      const result = prepareDataForApiEdit(originalFormData);

      expect(result).toEqual({
        branch: 'main',
        commit_message: 'Update file content',
      });
    });

    it('returns branch and commit_message when branch_name equals original_branch', () => {
      const originalFormData = {
        branch_name: 'main',
        original_branch: 'main',
        commit_message: 'Update file content',
      };

      const result = prepareDataForApiEdit(originalFormData);

      expect(result).toEqual({
        branch: 'main',
        commit_message: 'Update file content',
      });
    });

    it('includes start_branch when creating a new branch', () => {
      const originalFormData = {
        branch_name: 'feature-branch',
        original_branch: 'main',
        commit_message: 'Add new feature',
      };

      const result = prepareDataForApiEdit(originalFormData);

      expect(result).toEqual({
        branch: 'feature-branch',
        commit_message: 'Add new feature',
        start_branch: 'main',
      });
    });

    it('uses branch_name over original_branch when both are provided', () => {
      const originalFormData = {
        branch_name: 'develop',
        original_branch: 'main',
        commit_message: 'Merge changes',
      };

      const result = prepareDataForApiEdit(originalFormData);

      expect(result).toEqual({
        branch: 'develop',
        commit_message: 'Merge changes',
        start_branch: 'main',
      });
    });

    it.each([
      ['empty', ''],
      ['null', null],
      ['undefined', undefined],
    ])('handles %s branch_name by falling back to original_branch', (_, branchName) => {
      const originalFormData = {
        branch_name: branchName,
        original_branch: 'main',
        commit_message: 'Fix bug',
      };

      const result = prepareDataForApiEdit(originalFormData);

      expect(result).toEqual({
        branch: 'main',
        commit_message: 'Fix bug',
      });
    });

    it('handles special characters in branch names', () => {
      const originalFormData = {
        branch_name: 'feature/special-chars_123',
        original_branch: 'main',
        commit_message: 'Add feature with special chars',
      };

      const result = prepareDataForApiEdit(originalFormData);

      expect(result).toEqual({
        branch: 'feature/special-chars_123',
        commit_message: 'Add feature with special chars',
        start_branch: 'main',
      });
    });
  });
});
