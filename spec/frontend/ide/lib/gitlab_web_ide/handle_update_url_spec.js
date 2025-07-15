import { handleUpdateUrl } from '~/ide/lib/gitlab_web_ide/handle_update_url';

const MOCK_PROJECT_NAME = 'project-path';
const MOCK_BRANCH_NAME = 'branch';
const RELATIVE_URL_ROOT = '/gitlab';
const WINDOW_RELOAD = window.location.reload;

describe('ide/handle_update_url', () => {
  beforeAll(() => {
    Object.defineProperty(window, 'location', {
      value: { reload: jest.fn() },
    });
  });
  beforeEach(() => {
    window.gon.relative_url_root = '';
  });

  afterAll(() => {
    window.location.reload = WINDOW_RELOAD;
  });

  it('updates the URL and reloads the page', () => {
    const historySpy = jest.spyOn(window.history, 'replaceState');
    const locationSpy = jest.spyOn(window.location, 'reload');
    handleUpdateUrl({ projectPath: MOCK_PROJECT_NAME, ref: MOCK_BRANCH_NAME });

    expect(historySpy).toHaveBeenCalledTimes(1);
    expect(locationSpy).toHaveBeenCalledTimes(1);
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
