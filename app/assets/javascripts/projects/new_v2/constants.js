import { s__ } from '~/locale';

export const OPTIONS = {
  blank: {
    key: 'blank',
    value: 'blank_project',
    selector: '#blank-project-pane',
    title: s__('ProjectsNew|Create blank project'),
    description: s__(
      'ProjectsNew|Create a blank project to store your files, plan your work, and collaborate on code, among other things.',
    ),
  },
  template: {
    key: 'template',
    value: 'create_from_template',
    selector: '#create-from-template-pane',
    title: s__('ProjectsNew|Create from template'),
    description: s__(
      'ProjectsNew|Create a project pre-populated with the necessary files to get you started quickly.',
    ),
  },
  ci: {
    key: 'ci',
    value: 'cicd_for_external_repo',
    selector: '#ci-cd-project-pane',
    title: s__('ProjectsNew|Run CI/CD for external repository'),
    description: s__('ProjectsNew|Connect your external repository to GitLab CI/CD.'),
  },
  import: {
    key: 'import',
    value: 'import_project',
    selector: '#import-project-pane',
    title: s__('ProjectsNew|Import project'),
    description: s__(
      'ProjectsNew|Migrate your data from an external source like GitHub, Bitbucket, or another instance of GitLab.',
    ),
    icons: ['tanuki', 'github', 'bitbucket', 'gitea'],
    disabledMessage: s__(
      'ProjectsNew|Contact an administrator to enable options for importing your project',
    ),
  },
  transfer: {
    key: 'transfer',
    value: 'transfer_project',
    selector: '#transfer-project-pane',
    title: s__('ProjectsNew|Direct transfer projects with a top-level Group'),
    description: s__('ProjectsNew|Migrate your data from another GitLab instance.'),
    disabled: true,
    disabledMessage: s__('ProjectsNew|Available only for projects within groups'),
  },
};
