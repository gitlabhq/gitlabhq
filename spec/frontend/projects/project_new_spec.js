import $ from 'jquery';
import { TEST_HOST } from 'helpers/test_constants';
import projectNew from '~/projects/project_new';

describe('New Project', () => {
  let $projectImportUrl;
  let $projectPath;
  let $projectName;

  beforeEach(() => {
    setFixtures(`
      <div class='toggle-import-form'>
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
      </div>
    `);

    $projectImportUrl = $('#project_import_url');
    $projectPath = $('#project_path');
    $projectName = $('#project_name');
  });

  describe('deriveProjectPathFromUrl', () => {
    const dummyImportUrl = `${TEST_HOST}/dummy/import/url.git`;

    beforeEach(() => {
      projectNew.bindEvents();
      $projectPath.val('').keyup().val(dummyImportUrl);
    });

    it('does not change project path for disabled $projectImportUrl', () => {
      $projectImportUrl.prop('disabled', true);

      projectNew.deriveProjectPathFromUrl($projectImportUrl);

      expect($projectPath.val()).toEqual(dummyImportUrl);
    });

    describe('for enabled $projectImportUrl', () => {
      beforeEach(() => {
        $projectImportUrl.prop('disabled', false);
      });

      it('does not change project path if it is set by user', () => {
        $projectPath.keyup();

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual(dummyImportUrl);
      });

      it('does not change project path for empty $projectImportUrl', () => {
        $projectImportUrl.val('');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual(dummyImportUrl);
      });

      it('does not change project path for whitespace $projectImportUrl', () => {
        $projectImportUrl.val('   ');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual(dummyImportUrl);
      });

      it('does not change project path for $projectImportUrl without slashes', () => {
        $projectImportUrl.val('has-no-slash');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual(dummyImportUrl);
      });

      it('changes project path to last $projectImportUrl component', () => {
        $projectImportUrl.val('/this/is/last');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual('last');
      });

      it('ignores trailing slashes in $projectImportUrl', () => {
        $projectImportUrl.val('/has/trailing/slash/');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual('slash');
      });

      it('ignores fragment identifier in $projectImportUrl', () => {
        $projectImportUrl.val('/this/has/a#fragment-identifier/');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual('a');
      });

      it('ignores query string in $projectImportUrl', () => {
        $projectImportUrl.val('/url/with?query=string');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual('with');
      });

      it('ignores trailing .git in $projectImportUrl', () => {
        $projectImportUrl.val('/repository.git');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual('repository');
      });

      it('changes project path for HTTPS URL in $projectImportUrl', () => {
        $projectImportUrl.val('https://gitlab.company.com/group/project.git');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual('project');
      });

      it('changes project path for SSH URL in $projectImportUrl', () => {
        $projectImportUrl.val('git@gitlab.com:gitlab-org/gitlab-ce.git');

        projectNew.deriveProjectPathFromUrl($projectImportUrl);

        expect($projectPath.val()).toEqual('gitlab-ce');
      });
    });
  });

  describe('deriveSlugFromProjectName', () => {
    beforeEach(() => {
      projectNew.bindEvents();
      $projectName.val('').keyup();
    });

    it('converts project name to lower case and dash-limited slug', () => {
      const dummyProjectName = 'My Awesome Project';

      $projectName.val(dummyProjectName);

      projectNew.onProjectNameChange($projectName, $projectPath);

      expect($projectPath.val()).toEqual('my-awesome-project');
    });

    it('does not add additional dashes in the slug if the project name already contains dashes', () => {
      const dummyProjectName = 'My-Dash-Delimited Awesome Project';

      $projectName.val(dummyProjectName);

      projectNew.onProjectNameChange($projectName, $projectPath);

      expect($projectPath.val()).toEqual('my-dash-delimited-awesome-project');
    });
  });

  describe('derivesProjectNameFromSlug', () => {
    const dummyProjectPath = 'my-awesome-project';
    const dummyProjectName = 'Original Awesome Project';

    beforeEach(() => {
      projectNew.bindEvents();
      $projectPath.val('').change();
    });

    it('converts slug to humanized project name', () => {
      $projectPath.val(dummyProjectPath);

      projectNew.onProjectPathChange($projectName, $projectPath);

      expect($projectName.val()).toEqual('My Awesome Project');
    });

    it('does not convert slug to humanized project name if a project name already exists', () => {
      $projectName.val(dummyProjectName);
      $projectPath.val(dummyProjectPath);
      projectNew.onProjectPathChange(
        $projectName,
        $projectPath,
        $projectName.val().trim().length > 0,
      );

      expect($projectName.val()).toEqual(dummyProjectName);
    });
  });
});
