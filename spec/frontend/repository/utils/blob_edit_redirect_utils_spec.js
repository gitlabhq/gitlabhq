import * as urlUtility from '~/lib/utils/url_utility';
import * as localStorageAlert from '~/lib/utils/local_storage_alert';
import { VARIANT_INFO } from '~/alert';
import {
  buildBlobViewPath,
  redirectToExistingMergeRequest,
  redirectToCreateMergeRequest,
  redirectToForkMergeRequest,
  redirectToBlobWithAlert,
} from '~/repository/utils/blob_edit_redirect_utils';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

jest.mock('~/lib/utils/local_storage_alert', () => ({
  saveAlertToLocalStorage: jest.fn(),
}));

describe('blobEditRedirectUtils', () => {
  const baseUrl = 'https://gitlab.com/namespace/project/-/blob/main/README.md';

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('buildBlobViewPath', () => {
    it('builds the correct blob view path', () => {
      const result = buildBlobViewPath(baseUrl, {
        targetPath: '/namespace/project',
        branch: 'feature-branch',
        filePath: 'src/file.js',
      });

      expect(result).toBe('https://gitlab.com/namespace/project/-/blob/feature-branch/src/file.js');
    });

    it('handles nested file paths', () => {
      const result = buildBlobViewPath(baseUrl, {
        targetPath: '/group/subgroup/project',
        branch: 'main',
        filePath: 'app/models/user.rb',
      });

      expect(result).toBe(
        'https://gitlab.com/group/subgroup/project/-/blob/main/app/models/user.rb',
      );
    });
  });

  describe('redirectToExistingMergeRequest', () => {
    it('redirects to the existing merge request', () => {
      redirectToExistingMergeRequest({
        url: 'https://gitlab.com/namespace/project/-/blob/main/file.js?from_merge_request_iid=42',
        projectPath: '/namespace/project',
        fromMergeRequestIid: '42',
      });

      expect(urlUtility.visitUrl).toHaveBeenCalledWith(
        'https://gitlab.com/namespace/project/-/merge_requests/42',
      );
    });
  });

  describe('redirectToCreateMergeRequest', () => {
    it('redirects to create merge request with source branch', () => {
      redirectToCreateMergeRequest({
        newMergeRequestPath: 'https://gitlab.com/namespace/project/-/merge_requests/new',
        sourceBranch: 'feature-branch',
      });

      expect(urlUtility.visitUrl).toHaveBeenCalledWith(
        'https://gitlab.com/namespace/project/-/merge_requests/new?merge_request%5Bsource_branch%5D=feature-branch',
      );
    });

    it('handles branch names with special characters', () => {
      redirectToCreateMergeRequest({
        newMergeRequestPath: 'https://gitlab.com/namespace/project/-/merge_requests/new',
        sourceBranch: 'feature/my-branch',
      });

      expect(urlUtility.visitUrl).toHaveBeenCalledWith(
        expect.stringContaining('merge_request%5Bsource_branch%5D=feature%2Fmy-branch'),
      );
    });
  });

  describe('redirectToForkMergeRequest', () => {
    it('redirects to create merge request from fork', () => {
      redirectToForkMergeRequest({
        url: 'https://gitlab.com/user/forked-project/-/blob/main/file.js',
        forkProjectPath: '/user/forked-project',
        sourceBranch: 'patch-1',
        upstreamProjectId: '123',
        targetBranch: 'main',
      });

      const calledUrl = urlUtility.visitUrl.mock.calls[0][0];

      expect(calledUrl).toContain('/user/forked-project/-/merge_requests/new');
      expect(calledUrl).toContain('merge_request%5Bsource_branch%5D=patch-1');
      expect(calledUrl).toContain('merge_request%5Btarget_project_id%5D=123');
      expect(calledUrl).toContain('merge_request%5Btarget_branch%5D=main');
    });

    it('includes all required merge request parameters', () => {
      redirectToForkMergeRequest({
        url: 'https://gitlab.com/fork/project/-/blob/feature/file.js',
        forkProjectPath: '/fork/project',
        sourceBranch: 'my-feature',
        upstreamProjectId: '100',
        targetBranch: 'develop',
      });

      const calledUrl = urlUtility.visitUrl.mock.calls[0][0];

      expect(calledUrl).toContain('merge_request%5Bsource_branch%5D=my-feature');
      expect(calledUrl).toContain('merge_request%5Btarget_project_id%5D=100');
      expect(calledUrl).toContain('merge_request%5Btarget_branch%5D=develop');
    });
  });

  describe('redirectToBlobWithAlert', () => {
    const successMessageFn = jest.fn().mockReturnValue('Success message');

    beforeEach(() => {
      successMessageFn.mockClear();
    });

    it('redirects to blob view with success alert', () => {
      redirectToBlobWithAlert({
        url: 'https://gitlab.com/namespace/project/-/blob/main/old-file.js',
        resultingBranch: 'feature-branch',
        responseData: { file_path: 'new-file.js' },
        formData: { file_path: 'new-file.js', create_merge_request: false },
        isNewBranch: true,
        targetProjectPath: '/namespace/project',
        successMessageFn,
      });

      expect(localStorageAlert.saveAlertToLocalStorage).toHaveBeenCalledWith({
        message: 'Success message',
        messageLinks: {
          changesLink: 'https://gitlab.com/namespace/project/-/blob/feature-branch/new-file.js',
        },
        variant: VARIANT_INFO,
      });

      expect(urlUtility.visitUrl).toHaveBeenCalledWith(
        'https://gitlab.com/namespace/project/-/blob/feature-branch/new-file.js',
      );
    });

    it('uses formData.file_path when responseData.file_path is not available', () => {
      redirectToBlobWithAlert({
        url: 'https://gitlab.com/namespace/project/-/blob/main/file.js',
        resultingBranch: 'main',
        responseData: {},
        formData: { file_path: 'fallback-file.js', create_merge_request: true },
        isNewBranch: false,
        targetProjectPath: '/namespace/project',
        successMessageFn,
      });

      expect(urlUtility.visitUrl).toHaveBeenCalledWith(expect.stringContaining('fallback-file.js'));
    });

    it('removes from_merge_request_iid parameter from URL', () => {
      redirectToBlobWithAlert({
        url: 'https://gitlab.com/namespace/project/-/blob/main/file.js?from_merge_request_iid=42',
        resultingBranch: 'main',
        responseData: { file_path: 'file.js' },
        formData: { file_path: 'file.js', create_merge_request: false },
        isNewBranch: false,
        targetProjectPath: '/namespace/project',
        successMessageFn,
      });

      expect(urlUtility.visitUrl).toHaveBeenCalledWith(
        expect.not.stringContaining('from_merge_request_iid'),
      );
    });

    it('calls successMessageFn with correct parameters when new branch and MR not chosen', () => {
      redirectToBlobWithAlert({
        url: 'https://gitlab.com/namespace/project/-/blob/main/file.js',
        resultingBranch: 'new-branch',
        responseData: { file_path: 'file.js' },
        formData: { file_path: 'file.js', create_merge_request: false },
        isNewBranch: true,
        targetProjectPath: '/namespace/project',
        successMessageFn,
      });

      expect(successMessageFn).toHaveBeenCalledWith(true, true);
    });

    it('calls successMessageFn with correct parameters when same branch', () => {
      redirectToBlobWithAlert({
        url: 'https://gitlab.com/namespace/project/-/blob/main/file.js',
        resultingBranch: 'main',
        responseData: { file_path: 'file.js' },
        formData: { file_path: 'file.js', create_merge_request: false },
        isNewBranch: false,
        targetProjectPath: '/namespace/project',
        successMessageFn,
      });

      expect(successMessageFn).toHaveBeenCalledWith(false, true);
    });

    it('calls successMessageFn with correct parameters when MR is chosen', () => {
      redirectToBlobWithAlert({
        url: 'https://gitlab.com/namespace/project/-/blob/main/file.js',
        resultingBranch: 'new-branch',
        responseData: { file_path: 'file.js' },
        formData: { file_path: 'file.js', create_merge_request: true },
        isNewBranch: true,
        targetProjectPath: '/namespace/project',
        successMessageFn,
      });

      expect(successMessageFn).toHaveBeenCalledWith(true, false);
    });
  });
});
