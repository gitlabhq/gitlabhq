import $ from 'jquery';
import { getParameterValues } from '../lib/utils/url_utility';
import projectNew from './project_new';

export default () => {
  const pathParam = getParameterValues('path')[0];
  const nameParam = getParameterValues('name')[0];
  const $projectPath = $('.js-path-name');
  const $projectName = $('.js-project-name');

  // get the path url and append it in the input
  $projectPath.val(pathParam);

  // get the project name from the URL and set it as input value
  $projectName.val(nameParam);

  // generate slug when project name changes
  $projectName.keyup(() => projectNew.onProjectNameChange($projectName, $projectPath));
};
