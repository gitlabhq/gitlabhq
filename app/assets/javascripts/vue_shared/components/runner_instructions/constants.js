import { s__ } from '~/locale';

export const REGISTRATION_TOKEN_PLACEHOLDER = '$REGISTRATION_TOKEN';

export const INSTRUCTIONS_PLATFORMS_WITHOUT_ARCHITECTURES = {
  docker: {
    instructions: s__(
      'Runners|To install Runner in a container follow the instructions described in the GitLab documentation',
    ),
    link: 'https://docs.gitlab.com/runner/install/docker.html',
  },
  kubernetes: {
    instructions: s__(
      'Runners|To install Runner in Kubernetes follow the instructions described in the GitLab documentation.',
    ),
    link: 'https://docs.gitlab.com/runner/install/kubernetes.html',
  },
};
