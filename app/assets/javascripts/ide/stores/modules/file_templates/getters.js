export const templateTypes = () => [
  {
    name: '.gitlab-ci.yml',
    key: 'gitlab_ci_ymls',
  },
  {
    name: '.gitignore',
    key: 'gitignores',
  },
  {
    name: 'LICENSE',
    key: 'licenses',
  },
  {
    name: 'Dockerfile',
    key: 'dockerfiles',
  },
];

export const showFileTemplatesBar = (_, getters) => name =>
  getters.templateTypes.find(t => t.name === name);

export default () => {};
