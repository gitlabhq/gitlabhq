import { APPLICATION_STATUS } from '~/clusters/constants';

const CLUSTERS_MOCK_DATA = {
  GET: {
    '/gitlab-org/gitlab-shell/clusters/1/status.json': {
      data: {
        status: 'errored',
        status_reason: 'Failed to request to CloudPlatform.',
        applications: [
          {
            name: 'helm',
            status: APPLICATION_STATUS.INSTALLABLE,
            status_reason: null,
            can_uninstall: false,
          },
          {
            name: 'ingress',
            status: APPLICATION_STATUS.ERROR,
            status_reason: 'Cannot connect',
            external_ip: null,
            external_hostname: null,
            can_uninstall: false,
          },
          {
            name: 'runner',
            status: APPLICATION_STATUS.INSTALLING,
            status_reason: null,
            can_uninstall: false,
          },
          {
            name: 'prometheus',
            status: APPLICATION_STATUS.ERROR,
            status_reason: 'Cannot connect',
            can_uninstall: false,
          },
          {
            name: 'jupyter',
            status: APPLICATION_STATUS.INSTALLING,
            status_reason: 'Cannot connect',
            can_uninstall: false,
          },
          {
            name: 'knative',
            status: APPLICATION_STATUS.INSTALLING,
            status_reason: 'Cannot connect',
            can_uninstall: false,
          },
          {
            name: 'cert_manager',
            status: APPLICATION_STATUS.ERROR,
            status_reason: 'Cannot connect',
            email: 'test@example.com',
            can_uninstall: false,
          },
          {
            name: 'crossplane',
            status: APPLICATION_STATUS.ERROR,
            status_reason: 'Cannot connect',
            can_uninstall: false,
          },
          {
            name: 'elastic_stack',
            status: APPLICATION_STATUS.ERROR,
            status_reason: 'Cannot connect',
            can_uninstall: false,
          },
        ],
      },
    },
    '/gitlab-org/gitlab-shell/clusters/2/status.json': {
      data: {
        status: 'errored',
        status_reason: 'Failed to request to CloudPlatform.',
        applications: [
          {
            name: 'helm',
            status: APPLICATION_STATUS.INSTALLED,
            status_reason: null,
          },
          {
            name: 'ingress',
            status: APPLICATION_STATUS.INSTALLED,
            status_reason: 'Cannot connect',
            external_ip: '1.1.1.1',
            external_hostname: null,
          },
          {
            name: 'runner',
            status: APPLICATION_STATUS.INSTALLING,
            status_reason: null,
          },
          {
            name: 'prometheus',
            status: APPLICATION_STATUS.ERROR,
            status_reason: 'Cannot connect',
          },
          {
            name: 'jupyter',
            status: APPLICATION_STATUS.INSTALLABLE,
            status_reason: 'Cannot connect',
          },
          {
            name: 'knative',
            status: APPLICATION_STATUS.INSTALLABLE,
            status_reason: 'Cannot connect',
          },
          {
            name: 'cert_manager',
            status: APPLICATION_STATUS.ERROR,
            status_reason: 'Cannot connect',
            email: 'test@example.com',
          },
          {
            name: 'crossplane',
            status: APPLICATION_STATUS.ERROR,
            status_reason: 'Cannot connect',
            stack: 'gcp',
          },
          {
            name: 'elastic_stack',
            status: APPLICATION_STATUS.ERROR,
            status_reason: 'Cannot connect',
          },
        ],
      },
    },
  },
  POST: {
    '/gitlab-org/gitlab-shell/clusters/1/applications/helm': {},
    '/gitlab-org/gitlab-shell/clusters/1/applications/ingress': {},
    '/gitlab-org/gitlab-shell/clusters/1/applications/crossplane': {},
    '/gitlab-org/gitlab-shell/clusters/1/applications/cert_manager': {},
    '/gitlab-org/gitlab-shell/clusters/1/applications/runner': {},
    '/gitlab-org/gitlab-shell/clusters/1/applications/prometheus': {},
    '/gitlab-org/gitlab-shell/clusters/1/applications/jupyter': {},
    '/gitlab-org/gitlab-shell/clusters/1/applications/knative': {},
    '/gitlab-org/gitlab-shell/clusters/1/applications/elastic_stack': {},
  },
};

const DEFAULT_APPLICATION_STATE = {
  id: 'some-app',
  title: 'My App',
  titleLink: 'https://about.gitlab.com/',
  description: 'Some description about this interesting application!',
  status: null,
  statusReason: null,
  requestReason: null,
};

const APPLICATIONS_MOCK_STATE = {
  helm: { title: 'Helm Tiller', status: 'installable' },
  ingress: { title: 'Ingress', status: 'installable' },
  crossplane: { title: 'Crossplane', status: 'installable', stack: '' },
  cert_manager: { title: 'Cert-Manager', status: 'installable' },
  runner: { title: 'GitLab Runner' },
  prometheus: { title: 'Prometheus' },
  jupyter: { title: 'JupyterHub', status: 'installable', hostname: '' },
  knative: { title: 'Knative ', status: 'installable', hostname: '' },
  elastic_stack: { title: 'Elastic Stack', status: 'installable', kibana_hostname: '' },
};

export { CLUSTERS_MOCK_DATA, DEFAULT_APPLICATION_STATE, APPLICATIONS_MOCK_STATE };
