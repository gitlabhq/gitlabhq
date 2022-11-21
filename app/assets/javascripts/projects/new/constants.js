import { s__ } from '~/locale';

export const K8S_OPTION = s__('DeploymentTarget|Kubernetes (GKE, EKS, OpenShift, and so on)');

export const DEPLOYMENT_TARGET_SELECTIONS = [
  K8S_OPTION,
  s__('DeploymentTarget|Managed container runtime (Fargate, Cloud Run, DigitalOcean App)'),
  s__('DeploymentTarget|Self-managed container runtime (Podman, Docker Swarm, Docker Compose)'),
  s__('DeploymentTarget|Heroku'),
  s__('DeploymentTarget|Virtual machine (for example, EC2)'),
  s__('DeploymentTarget|Mobile app store'),
  s__('DeploymentTarget|Registry (package or container)'),
  s__('DeploymentTarget|Infrastructure provider (Terraform, Cloudformation, and so on)'),
  s__('DeploymentTarget|Serverless backend (Lambda, Cloud functions)'),
  s__('DeploymentTarget|Edge Computing (e.g. Cloudflare Workers)'),
  s__('DeploymentTarget|Web Deployment Platform (Netlify, Vercel, Gatsby)'),
  s__('DeploymentTarget|GitLab Pages'),
  s__('DeploymentTarget|Other hosting service'),
  s__('DeploymentTarget|No deployment planned'),
];

export const NEW_PROJECT_FORM = 'new_project';
export const DEPLOYMENT_TARGET_LABEL = 'new_project_deployment_target';
export const DEPLOYMENT_TARGET_EVENT = 'select_deployment_target';
export const VISIT_DOCS_EVENT = 'visit_docs';
