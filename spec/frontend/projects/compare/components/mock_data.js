const refsProjectPath = 'some/refs/path';
const paramsName = 'to';
const paramsBranch = 'main';
const defaultProject = {
  name: 'some-to-name',
  id: '1',
};

export const appDefaultProps = {
  projectCompareIndexPath: 'some/path',
  projectMergeRequestPath: '',
  projects: [defaultProject],
  paramsFrom: 'main',
  paramsTo: 'target/branch',
  createMrPath: '',
  refsProjectPath,
  defaultProject,
};

export const revisionCardDefaultProps = {
  selectedProject: defaultProject,
  paramsBranch,
  revisionText: 'Source',
  refsProjectPath,
  paramsName,
};

export const repoDropdownDefaultProps = {
  selectedProject: defaultProject,
  paramsName,
};

export const revisionDropdownDefaultProps = {
  refsProjectPath,
  paramsBranch,
  paramsName,
};
