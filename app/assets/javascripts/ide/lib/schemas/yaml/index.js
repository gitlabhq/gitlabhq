import gitlabCi from './gitlab_ci';

export default {
  language: 'yaml',
  options: {
    validate: true,
    enableSchemaRequest: true,
    hover: true,
    completion: true,
    schemas: [gitlabCi],
  },
};
