import { convertToTitleCase, humanize, slugify } from '../lib/utils/text_utility';
import { getParameterValues } from '../lib/utils/url_utility';
import projectNew from './project_new';

const prepareParameters = () => {
  const name = getParameterValues('name')[0];
  const path = getParameterValues('path')[0];

  // If the name param exists but the path doesn't then generate it from the name
  if (name && !path) {
    return { name, path: slugify(name) };
  }

  // If the path param exists but the name doesn't then generate it from the path
  if (path && !name) {
    return { name: convertToTitleCase(humanize(path, '-')), path };
  }

  return { name, path };
};

export default () => {
  let hasUserDefinedProjectName = false;
  const $projectName = document.querySelector('.js-project-name');
  const $projectPath = document.querySelector('.js-path-name');
  const { name, path } = prepareParameters();

  // get the project name from the URL and set it as input value
  $projectName.value = name;

  // get the path url and append it in the input
  $projectPath.value = path;

  // generate slug when project name changes
  $projectName.addEventListener('keyup', () => {
    projectNew.onProjectNameChange($projectName, $projectPath);
    hasUserDefinedProjectName = $projectName.value.trim().length > 0;
  });

  // generate project name from the slug if one isn't set
  $projectPath.addEventListener('keyup', () =>
    projectNew.onProjectPathChange($projectName, $projectPath, hasUserDefinedProjectName),
  );
};
