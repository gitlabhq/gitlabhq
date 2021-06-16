import { s__, sprintf } from '~/locale';

export const EXPERIMENT_NAME = 'ci_runner_templates';

export const README_URL =
  'https://gitlab.com/guided-explorations/aws/gitlab-runner-autoscaling-aws-asg/-/blob/main/easybuttons.md';

export const CF_BASE_URL =
  'https://us-west-2.console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/create/review?';

export const TEMPLATES_BASE_URL = 'https://gl-public-templates.s3.amazonaws.com/cfn/experimental/';

export const EASY_BUTTONS = [
  {
    stackName: 'linux-docker-nonspot',
    templateName:
      'easybutton-amazon-linux-2-docker-manual-scaling-with-schedule-ondemandonly.cf.yml',
    description: s__(
      'Runners|Amazon Linux 2 Docker HA with manual scaling and optional scheduling. Non-spot. Default choice for Linux Docker executor.',
    ),
  },
  {
    stackName: 'linux-docker-spotonly',
    templateName: 'easybutton-amazon-linux-2-docker-manual-scaling-with-schedule-spotonly.cf.yml',
    description: sprintf(
      s__(
        'Runners|Amazon Linux 2 Docker HA with manual scaling and optional scheduling. %{percentage} spot.',
      ),
      { percentage: '100%' },
    ),
  },
  {
    stackName: 'win2019-shell-non-spot',
    templateName: 'easybutton-windows2019-shell-manual-scaling-with-scheduling-ondemandonly.cf.yml',
    description: s__(
      'Runners|Windows 2019 Shell with manual scaling and optional scheduling. Non-spot. Default choice for Windows Shell executor.',
    ),
  },
  {
    stackName: 'win2019-shell-spot',
    templateName: 'easybutton-windows2019-shell-manual-scaling-with-scheduling-spotonly.cf.yml',
    description: sprintf(
      s__(
        'Runners|Windows 2019 Shell with manual scaling and optional scheduling. %{percentage} spot.',
      ),
      { percentage: '100%' },
    ),
  },
];
