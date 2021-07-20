import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import Api from '~/api';
import { convertObjectPropsToSnakeCase } from '~/lib/utils/common_utils';

import {
  SUBMIT_CHANGES_BRANCH_ERROR,
  SUBMIT_CHANGES_COMMIT_ERROR,
  SUBMIT_CHANGES_MERGE_REQUEST_ERROR,
  TRACKING_ACTION_CREATE_COMMIT,
  TRACKING_ACTION_CREATE_MERGE_REQUEST,
  SERVICE_PING_TRACKING_ACTION_CREATE_COMMIT,
  SERVICE_PING_TRACKING_ACTION_CREATE_MERGE_REQUEST,
  DEFAULT_FORMATTING_CHANGES_COMMIT_MESSAGE,
  DEFAULT_FORMATTING_CHANGES_COMMIT_DESCRIPTION,
} from '~/static_site_editor/constants';
import generateBranchName from '~/static_site_editor/services/generate_branch_name';
import submitContentChanges from '~/static_site_editor/services/submit_content_changes';

import {
  username,
  projectId,
  commitBranchResponse,
  commitMultipleResponse,
  createMergeRequestResponse,
  mergeRequestMeta,
  sourcePath,
  branch as targetBranch,
  sourceContentYAML as content,
  trackingCategory,
  images,
} from '../mock_data';

jest.mock('~/static_site_editor/services/generate_branch_name');

describe('submitContentChanges', () => {
  const sourceBranch = 'branch-name';
  let trackingSpy;
  let origPage;

  const buildPayload = (overrides = {}) => ({
    username,
    projectId,
    sourcePath,
    targetBranch,
    content,
    images,
    mergeRequestMeta,
    ...overrides,
  });

  beforeEach(() => {
    jest.spyOn(Api, 'createBranch').mockResolvedValue({ data: commitBranchResponse });
    jest.spyOn(Api, 'commitMultiple').mockResolvedValue({ data: commitMultipleResponse });
    jest
      .spyOn(Api, 'createProjectMergeRequest')
      .mockResolvedValue({ data: createMergeRequestResponse });

    generateBranchName.mockReturnValue(sourceBranch);

    origPage = document.body.dataset.page;
    document.body.dataset.page = trackingCategory;
    trackingSpy = mockTracking(document.body.dataset.page, undefined, jest.spyOn);
  });

  afterEach(() => {
    document.body.dataset.page = origPage;
    unmockTracking();
  });

  it('creates a branch named after the username and target branch', () => {
    return submitContentChanges(buildPayload()).then(() => {
      expect(Api.createBranch).toHaveBeenCalledWith(projectId, {
        ref: targetBranch,
        branch: sourceBranch,
      });
    });
  });

  it('notifies error when branch could not be created', () => {
    Api.createBranch.mockRejectedValueOnce();

    return expect(submitContentChanges(buildPayload())).rejects.toThrow(
      SUBMIT_CHANGES_BRANCH_ERROR,
    );
  });

  describe('committing markdown formatting changes', () => {
    const formattedMarkdown = `formatted ${content}`;
    const commitPayload = {
      branch: sourceBranch,
      commit_message: `${DEFAULT_FORMATTING_CHANGES_COMMIT_MESSAGE}\n\n${DEFAULT_FORMATTING_CHANGES_COMMIT_DESCRIPTION}`,
      actions: [
        {
          action: 'update',
          file_path: sourcePath,
          content: formattedMarkdown,
        },
      ],
    };

    it('commits markdown formatting changes in a separate commit', () => {
      return submitContentChanges(buildPayload({ formattedMarkdown })).then(() => {
        expect(Api.commitMultiple).toHaveBeenCalledWith(projectId, commitPayload);
      });
    });

    it('does not commit markdown formatting changes when there are none', () => {
      return submitContentChanges(buildPayload()).then(() => {
        expect(Api.commitMultiple.mock.calls).toHaveLength(1);
        expect(Api.commitMultiple.mock.calls[0][1]).not.toMatchObject({
          actions: commitPayload.actions,
        });
      });
    });
  });

  it('commits the content changes to the branch when creating branch succeeds', () => {
    return submitContentChanges(buildPayload()).then(() => {
      expect(Api.commitMultiple).toHaveBeenCalledWith(projectId, {
        branch: sourceBranch,
        commit_message: mergeRequestMeta.title,
        actions: [
          {
            action: 'update',
            file_path: sourcePath,
            content,
          },
          {
            action: 'create',
            content: 'image1-content',
            encoding: 'base64',
            file_path: 'path/to/image1.png',
          },
        ],
      });
    });
  });

  it('does not commit an image if it has been removed from the content', () => {
    const contentWithoutImages = '## Content without images';
    const payload = buildPayload({ content: contentWithoutImages });
    return submitContentChanges(payload).then(() => {
      expect(Api.commitMultiple).toHaveBeenCalledWith(projectId, {
        branch: sourceBranch,
        commit_message: mergeRequestMeta.title,
        actions: [
          {
            action: 'update',
            file_path: sourcePath,
            content: contentWithoutImages,
          },
        ],
      });
    });
  });

  it('notifies error when content could not be committed', () => {
    Api.commitMultiple.mockRejectedValueOnce();

    return expect(submitContentChanges(buildPayload())).rejects.toThrow(
      SUBMIT_CHANGES_COMMIT_ERROR,
    );
  });

  it('creates a merge request when committing changes succeeds', () => {
    return submitContentChanges(buildPayload()).then(() => {
      const { title, description } = mergeRequestMeta;
      expect(Api.createProjectMergeRequest).toHaveBeenCalledWith(
        projectId,
        convertObjectPropsToSnakeCase({
          title,
          description,
          targetBranch,
          sourceBranch,
        }),
      );
    });
  });

  it('notifies error when merge request could not be created', () => {
    Api.createProjectMergeRequest.mockRejectedValueOnce();

    return expect(submitContentChanges(buildPayload())).rejects.toThrow(
      SUBMIT_CHANGES_MERGE_REQUEST_ERROR,
    );
  });

  describe('when changes are submitted successfully', () => {
    let result;

    beforeEach(() => {
      return submitContentChanges(buildPayload()).then((_result) => {
        result = _result;
      });
    });

    it('returns the branch name', () => {
      expect(result).toMatchObject({ branch: { label: sourceBranch } });
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

  describe('sends the correct tracking event', () => {
    beforeEach(() => {
      return submitContentChanges(buildPayload());
    });

    it('for committing changes', () => {
      expect(trackingSpy).toHaveBeenCalledWith(
        document.body.dataset.page,
        TRACKING_ACTION_CREATE_COMMIT,
      );
    });

    it('for creating a merge request', () => {
      expect(trackingSpy).toHaveBeenCalledWith(
        document.body.dataset.page,
        TRACKING_ACTION_CREATE_MERGE_REQUEST,
      );
    });
  });

  describe('sends the correct Service Ping tracking event', () => {
    beforeEach(() => {
      jest.spyOn(Api, 'trackRedisCounterEvent').mockResolvedValue({ data: '' });
    });

    it('for commiting changes', () => {
      return submitContentChanges(buildPayload()).then(() => {
        expect(Api.trackRedisCounterEvent).toHaveBeenCalledWith(
          SERVICE_PING_TRACKING_ACTION_CREATE_COMMIT,
        );
      });
    });

    it('for creating a merge request', () => {
      return submitContentChanges(buildPayload()).then(() => {
        expect(Api.trackRedisCounterEvent).toHaveBeenCalledWith(
          SERVICE_PING_TRACKING_ACTION_CREATE_MERGE_REQUEST,
        );
      });
    });
  });
});
