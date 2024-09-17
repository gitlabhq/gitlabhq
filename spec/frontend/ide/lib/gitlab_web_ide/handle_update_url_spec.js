import { handleUpdateUrl } from '~/ide/lib/gitlab_web_ide/handle_update_url';

const MOCK_PROJECT_NAME = 'project-path';
const MOCK_BRANCH_NAME = 'branch';
const RELATIVE_URL_ROOT = '/gitlab';

describe('ide/handle_update_url', () => {
  beforeEach(() => {
    window.gon.relative_url_root = '';
  });

  it('does not update the url if no previous state stored', () => {
    const historySpy = jest.spyOn(window.history, 'replaceState');
    handleUpdateUrl({ projectPath: MOCK_PROJECT_NAME, ref: MOCK_BRANCH_NAME });

    expect(historySpy).toHaveBeenCalledTimes(0);
  });

  it('does not update the url if ref did not change', () => {
    window.history.replaceState({ previousRef: MOCK_BRANCH_NAME }, '');

    const historySpy = jest.spyOn(window.history, 'replaceState');
    handleUpdateUrl({ projectPath: MOCK_PROJECT_NAME, ref: MOCK_BRANCH_NAME });

    expect(historySpy).toHaveBeenCalledTimes(0);
  });

  describe('when the ref changes', () => {
    beforeEach(() => {
      handleUpdateUrl({ projectPath: MOCK_PROJECT_NAME, ref: 'some-ref' });
    });

    it('updates the url', () => {
      const historySpy = jest.spyOn(window.history, 'replaceState');
      handleUpdateUrl({ projectPath: MOCK_PROJECT_NAME, ref: MOCK_BRANCH_NAME });

      expect(historySpy).toHaveBeenCalledTimes(1);
      expect(historySpy).toHaveBeenCalledWith(
        null,
        '',
        `/-/ide/project/${MOCK_PROJECT_NAME}/edit/${MOCK_BRANCH_NAME}/-/`,
      );
    });

    it('includes the relative url root if it exists', () => {
      window.gon.relative_url_root = RELATIVE_URL_ROOT;
      const historySpy = jest.spyOn(window.history, 'replaceState');
      handleUpdateUrl({ projectPath: MOCK_PROJECT_NAME, ref: MOCK_BRANCH_NAME });

      expect(historySpy).toHaveBeenCalledTimes(1);
      expect(historySpy).toHaveBeenCalledWith(
        null,
        '',
        `${RELATIVE_URL_ROOT}/-/ide/project/${MOCK_PROJECT_NAME}/edit/${MOCK_BRANCH_NAME}/-/`,
      );
    });
  });
});
