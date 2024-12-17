import { s__ } from '~/locale';

export const K8S_OPTION = {
  value: 'kubernetes',
  text: s__('DeploymentTarget|Kubernetes (GKE, EKS, OpenShift, and so on)'),
};

export const DEPLOYMENT_TARGET_SELECTIONS = [
  K8S_OPTION,
  {
    value: 'managed_container_runtime',
    text: s__('DeploymentTarget|Managed container runtime (Fargate, Cloud Run, DigitalOcean App)'),
  },
  {
    value: 'self_managed_container_runtime',
    text: s__(
      'DeploymentTarget|Self-managed container runtime (Podman, Docker Swarm, Docker Compose)',
    ),
  },
  {
    value: 'heroku',
    text: s__('DeploymentTarget|Heroku'),
  },
  {
    value: 'virtual_machine',
    text: s__('DeploymentTarget|Virtual machine (for example, EC2)'),
  },
  {
    value: 'mobile_app_store',
    text: s__('DeploymentTarget|Mobile app store'),
  },
  {
    value: 'registry',
    text: s__('DeploymentTarget|Registry (package or container)'),
  },
  {
    value: 'infrastructure_provider',
    text: s__('DeploymentTarget|Infrastructure provider (Terraform, Cloudformation, and so on)'),
  },
  {
    value: 'serverless_backend',
    text: s__('DeploymentTarget|Serverless backend (Lambda, Cloud functions)'),
  },
  {
    value: 'edge_computing',
    text: s__('DeploymentTarget|Edge Computing (e.g. Cloudflare Workers)'),
  },
  {
    value: 'web_deployment_platform',
    text: s__('DeploymentTarget|Web Deployment Platform (Netlify, Vercel, Gatsby)'),
  },
  {
    value: 'gitlab_pages',
    text: s__('DeploymentTarget|GitLab Pages'),
  },
  {
    value: 'other_hosting_service',
    text: s__('DeploymentTarget|Other hosting service'),
  },
  {
    value: 'no_deployment',
    text: s__('DeploymentTarget|No deployment planned'),
  },
];

export const NEW_PROJECT_FORM = 'new_project';
export const DEPLOYMENT_TARGET_LABEL = 'new_project_deployment_target';
export const DEPLOYMENT_TARGET_EVENT = 'select_deployment_target';
export const VISIT_DOCS_EVENT = 'visit_docs';
