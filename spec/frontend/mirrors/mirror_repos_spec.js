import $ from 'jquery';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { createMirrorForm, createLegacyTable } from 'jest/mirrors/mock_data';
import MirrorRepos from '~/mirrors/mirror_repos';
import SSHMirror from '~/mirrors/ssh_mirror';

jest.mock('~/mirrors/ssh_mirror');

describe('MirrorRepos', () => {
  let mirrorRepos;

  const createContainer = ({ hasLegacyTable = false } = {}) => {
    setHTMLFixture(
      `<div class="js-mirror-settings">${createMirrorForm()}${
        hasLegacyTable ? createLegacyTable() : ''
      }</div>`,
    );
    return document.querySelector('.js-mirror-settings');
  };

  const createSubject = ({ hasLegacyTable = false } = {}) => {
    mirrorRepos = new MirrorRepos(createContainer({ hasLegacyTable }));
    jest.spyOn(mirrorRepos, 'deleteMirror').mockResolvedValue();
    jest.spyOn(mirrorRepos, 'registerTableListeners');
    mirrorRepos.init();
  };

  const findMirrorUrlInput = () => document.querySelector('.js-mirror-url');
  const findMirrorUrlHiddenInput = () => document.querySelector('.js-mirror-url-hidden');
  const findProtectedBranchesInput = () => document.querySelector('.js-mirror-protected');
  const findProtectedBranchesHiddenInput = () =>
    document.querySelector('.js-mirror-protected-hidden');
  const findDeleteMirrorButton = () => document.querySelector('.js-delete-mirror');

  beforeEach(() => {
    SSHMirror.mockImplementation(() => ({
      init: jest.fn(),
    }));
  });

  afterEach(() => {
    jest.restoreAllMocks();
    resetHTMLFixture();
  });

  it('registers form listeners', () => {
    createSubject();

    findMirrorUrlInput().value = 'https://example.com/updated.git';
    $(findMirrorUrlInput()).trigger('input');
    findProtectedBranchesInput().checked = true;
    $(findProtectedBranchesInput()).trigger('change');
    jest.runOnlyPendingTimers();

    expect(findMirrorUrlHiddenInput().value).toBe('https://example.com/updated.git');
    expect(findProtectedBranchesHiddenInput().value).toBe('1');
  });

  describe('legacy table listeners', () => {
    it('binds delete mirror clicks when the legacy table is present', () => {
      createSubject({ hasLegacyTable: true });

      $(findDeleteMirrorButton()).trigger('click');

      expect(mirrorRepos.registerTableListeners).toHaveBeenCalledTimes(1);
      expect(mirrorRepos.deleteMirror).toHaveBeenCalledTimes(1);
    });

    it('does not register table listeners when the legacy table is absent at init', () => {
      createSubject();

      expect(mirrorRepos.registerTableListeners).not.toHaveBeenCalled();
    });
  });
});
