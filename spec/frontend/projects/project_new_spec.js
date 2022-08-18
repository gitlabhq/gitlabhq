import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { TEST_HOST } from 'helpers/test_constants';
import projectNew from '~/projects/project_new';
import { mockTracking, triggerEvent, unmockTracking } from 'helpers/tracking_helper';

describe('New Project', () => {
  let $projectImportUrl;
  let $projectPath;
  let $projectName;

  const mockKeyup = (el) => el.dispatchEvent(new KeyboardEvent('keyup'));
  const mockChange = (el) => el.dispatchEvent(new Event('change'));

  beforeEach(() => {
    setHTMLFixture(`
      <div class="tab-pane active">
        <div class='toggle-import-form'>
          <form id="new_project">
            <div class='import-url-data'>
              <div class="form-group">
                <input id="project_import_url" />
              </div>
              <div id="import-url-auth-method">
                <div class="form-group">
                  <input id="project-import-url-user" />
                </div>
                <div class="form-group">
                  <input id="project_import_url_password" />
                </div>
              </div>
              <input id="project_name" />
              <input id="project_path" />
            </div>
            <div class="js-user-readme-repo"></div>
            <button class="js-create-project-button"/>
          </form>
        </div>
      </div>
    `);

    $projectImportUrl = document.querySelector('#project_import_url');
    $projectPath = document.querySelector('#project_path');
    $projectName = document.querySelector('#project_name');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  const setValueAndTriggerEvent = (el, value, event) => {
    event(el);
    el.value = value;
  };

  describe('tracks manual path input', () => {
    let trackingSpy;

    beforeEach(() => {
      trackingSpy = mockTracking('_category_', undefined, jest.spyOn);
      projectNew.bindEvents();
      $projectPath.oldInputValue = '_old_value_';
    });

    afterEach(() => {
      unmockTracking();
    });

    it('tracks the event', () => {
      $projectPath.value = '_new_value_';

      triggerEvent($projectPath, 'blur');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'user_input_path_slug', {
        label: 'new_project_form',
      });
    });

    it('does not track the event when there has been no change', () => {
      $projectPath.value = '_old_value_';

      triggerEvent($projectPath, 'blur');

      expect(trackingSpy).not.toHaveBeenCalled();
    });
  });

  describe('deriveProjectPathFromUrl', () => {
    const dummyImportUrl = `${TEST_HOST}/dummy/import/url.git`;

    beforeEach(() => {
      projectNew.bindEvents();
      setValueAndTriggerEvent($projectPath, dummyImportUrl, mockKeyup);
    });

    it('does not change project path for disabled $projectImportUrl', () => {
      $projectImportUrl.setAttribute('disabled', true);

      projectNew.deriveProjectPathFromUrl($projectImportUrl);

      expect($projectPath.value).toEqual(dummyImportUrl);
    });

    describe('for enabled $projectImportUrl', () => {
      beforeEach(() => {
        $projectImportUrl.setAttribute('disabled', false);
      });

      it('does not change project path if it is set by user', () => {
        mockKeyup($projectPath);

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.value).toEqual(dummyImportUrl);
      });

      it('does not change project path for empty $projectImportUrl', () => {
        $projectImportUrl.value = '';

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.value).toEqual(dummyImportUrl);
      });

      it('does not change project path for whitespace $projectImportUrl', () => {
        $projectImportUrl.value = '   ';

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.value).toEqual(dummyImportUrl);
      });

      it('does not change project path for $projectImportUrl without slashes', () => {
        $projectImportUrl.value = 'has-no-slash';

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.value).toEqual(dummyImportUrl);
      });

      it('changes project path to last $projectImportUrl component', () => {
        $projectImportUrl.value = '/this/is/last';

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.value).toEqual('last');
      });

      it('ignores trailing slashes in $projectImportUrl', () => {
        $projectImportUrl.value = '/has/trailing/slash/';

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.value).toEqual('slash');
      });

      it('ignores fragment identifier in $projectImportUrl', () => {
        $projectImportUrl.value = '/this/has/a#fragment-identifier/';

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.value).toEqual('a');
      });

      it('ignores query string in $projectImportUrl', () => {
        $projectImportUrl.value = '/url/with?query=string';

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.value).toEqual('with');
      });

      it('ignores trailing .git in $projectImportUrl', () => {
        $projectImportUrl.value = '/repository.git';

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.value).toEqual('repository');
      });

      it('changes project path for HTTPS URL in $projectImportUrl', () => {
        $projectImportUrl.value = 'https://gitlab.company.com/group/project.git';

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.value).toEqual('project');
      });

      it('changes project path for SSH URL in $projectImportUrl', () => {
        $projectImportUrl.value = 'git@gitlab.com:gitlab-org/gitlab-ce.git';

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.value).toEqual('gitlab-ce');
      });
    });
  });

  describe('deriveSlugFromProjectName', () => {
    beforeEach(() => {
      projectNew.bindEvents();
      setValueAndTriggerEvent($projectName, '', mockKeyup);
    });

    it('converts project name to lower case and dash-limited slug', () => {
      const dummyProjectName = 'My Awesome Project';

      $projectName.value = dummyProjectName;

      projectNew.onProjectNameChange($projectName, $projectPath);

      expect($projectPath.value).toEqual('my-awesome-project');
    });

    it('does not add additional dashes in the slug if the project name already contains dashes', () => {
      const dummyProjectName = 'My-Dash-Delimited Awesome Project';

      $projectName.value = dummyProjectName;

      projectNew.onProjectNameChange($projectName, $projectPath);

      expect($projectPath.value).toEqual('my-dash-delimited-awesome-project');
    });
  });

  describe('derivesProjectNameFromSlug', () => {
    const dummyProjectPath = 'my-awesome-project';
    const dummyProjectName = 'Original Awesome Project';

    beforeEach(() => {
      projectNew.bindEvents();
      setValueAndTriggerEvent($projectPath, '', mockChange);
    });

    it('converts slug to humanized project name', () => {
      $projectPath.value = dummyProjectPath;
      mockChange($projectPath);

      projectNew.onProjectPathChange($projectName, $projectPath);

      expect($projectName.value).toEqual('My Awesome Project');
    });

    it('does not convert slug to humanized project name if a project name already exists', () => {
      $projectName.value = dummyProjectName;
      $projectPath.value = dummyProjectPath;
      projectNew.onProjectPathChange(
        $projectName,
        $projectPath,
        $projectName.value.trim().length > 0,
      );

      expect($projectName.value).toEqual(dummyProjectName);
    });
  });
});
