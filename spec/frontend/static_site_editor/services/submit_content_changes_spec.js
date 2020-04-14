import Api from '~/api';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';

import {
  DEFAULT_TARGET_BRANCH,
  SUBMIT_CHANGES_BRANCH_ERROR,
  SUBMIT_CHANGES_COMMIT_ERROR,
  SUBMIT_CHANGES_MERGE_REQUEST_ERROR,
} from '~/static_site_editor/constants';
import generateBranchName from '~/static_site_editor/services/generate_branch_name';
import submitContentChanges from '~/static_site_editor/services/submit_content_changes';

import {
  username,
  projectId,
  commitMultipleResponse,
  createMergeRequestResponse,
  sourcePath,
  sourceContent as content,
} from '../mock_data';

jest.mock('~/static_site_editor/services/generate_branch_name');

describe('submitContentChanges', () => {
  const mergeRequestTitle = `Update ${sourcePath} file`;
  const branch = 'branch-name';

  beforeEach(() => {
    jest.spyOn(Api, 'createBranch').mockResolvedValue();
    jest.spyOn(Api, 'commitMultiple').mockResolvedValue({ data: commitMultipleResponse });
    jest
      .spyOn(Api, 'createProjectMergeRequest')
      .mockResolvedValue({ data: createMergeRequestResponse });

    generateBranchName.mockReturnValue(branch);
  });

  it('creates a branch named after the username and target branch', () => {
    return submitContentChanges({ username, projectId }).then(() => {
      expect(Api.createBranch).toHaveBeenCalledWith(projectId, {
        ref: DEFAULT_TARGET_BRANCH,
        branch,
      });
    });
  });

  it('notifies error when branch could not be created', () => {
    Api.createBranch.mockRejectedValueOnce();

    expect(submitContentChanges({ username, projectId })).rejects.toThrow(
      SUBMIT_CHANGES_BRANCH_ERROR,
    );
  });

  it('commits the content changes to the branch when creating branch succeeds', () => {
    return submitContentChanges({ username, projectId, sourcePath, content }).then(() => {
      expect(Api.commitMultiple).toHaveBeenCalledWith(projectId, {
        branch,
        commit_message: mergeRequestTitle,
        actions: [
          {
            action: 'update',
            file_path: sourcePath,
            content,
          },
        ],
      });
    });
  });

  it('notifies error when content could not be committed', () => {
    Api.commitMultiple.mockRejectedValueOnce();

    expect(submitContentChanges({ username, projectId })).rejects.toThrow(
      SUBMIT_CHANGES_COMMIT_ERROR,
    );
  });

  it('creates a merge request when commiting changes succeeds', () => {
    return submitContentChanges({ username, projectId, sourcePath, content }).then(() => {
      expect(Api.createProjectMergeRequest).toHaveBeenCalledWith(
        projectId,
        convertObjectPropsToSnakeCase({
          title: mergeRequestTitle,
          targetBranch: DEFAULT_TARGET_BRANCH,
          sourceBranch: branch,
        }),
      );
    });
  });

  it('notifies error when merge request could not be created', () => {
    Api.createProjectMergeRequest.mockRejectedValueOnce();

    expect(submitContentChanges({ username, projectId })).rejects.toThrow(
      SUBMIT_CHANGES_MERGE_REQUEST_ERROR,
    );
  });

  describe('when changes are submitted successfully', () => {
    let result;

    beforeEach(() => {
      return submitContentChanges({ username, projectId, sourcePath, content }).then(_result => {
        result = _result;
      });
    });

    it('returns the branch name', () => {
      expect(result).toMatchObject({ branch: { label: branch } });
    });

    it('returns commit short id and web url', () => {
      expect(result).toMatchObject({
        commit: {
          label: commitMultipleResponse.short_id,
          url: commitMultipleResponse.web_url,
        },
      });
    });

    it('returns merge request iid and web url', () => {
      expect(result).toMatchObject({
        mergeRequest: {
          label: createMergeRequestResponse.iid,
          url: createMergeRequestResponse.web_url,
        },
      });
    });
  });
});
