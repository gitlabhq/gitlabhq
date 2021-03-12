const projectPath = '';
export const HTTP_ID = 'gid://gitlab/AlertManagement::HttpIntegration/7';
export const PROMETHEUS_ID = 'gid://gitlab/PrometheusService/12';
export const errorMsg = 'Something went wrong';

export const createHttpVariables = {
  name: 'Test Pre',
  active: true,
  projectPath,
  type: 'HTTP',
};

export const updateHttpVariables = {
  name: 'Test Pre',
  active: true,
  id: HTTP_ID,
  type: 'HTTP',
};

export const createPrometheusVariables = {
  apiUrl: 'https://test-pre.com',
  active: true,
  projectPath,
  type: 'PROMETHEUS',
};

export const updatePrometheusVariables = {
  apiUrl: 'https://test-pre.com',
  active: true,
  id: PROMETHEUS_ID,
  type: 'PROMETHEUS',
};

export const getIntegrationsQueryResponse = {
  data: {
    project: {
      alertManagementIntegrations: {
        nodes: [
          {
            id: '37',
            type: 'HTTP',
            active: true,
            name: 'Test 5',
            url:
              'http://127.0.0.1:3000/h5bp/html5-boilerplate/alerts/notify/test-5/d4875758e67334f3.json',
            token: '89eb01df471d990ff5162a1c640408cf',
            apiUrl: null,
          },
          {
            id: '41',
            type: 'HTTP',
            active: true,
            name: 'Test 9999',
            url:
              'http://127.0.0.1:3000/h5bp/html5-boilerplate/alerts/notify/test-9999/b78a566e1776cfc2.json',
            token: 'f7579aa03844e07af3b1f0fca3f79f81',
            apiUrl: null,
          },
          {
            id: '40',
            type: 'HTTP',
            active: true,
            name: 'Test 6',
            url:
              'http://127.0.0.1:3000/h5bp/html5-boilerplate/alerts/notify/test-6/3e828ae28a240222.json',
            token: '6536102a607a5dd74fcdde921f2349ee',
            apiUrl: null,
          },
          {
            id: '12',
            type: 'PROMETHEUS',
            active: false,
            name: 'Prometheus',
            url: 'http://127.0.0.1:3000/h5bp/html5-boilerplate/prometheus/alerts/notify.json',
            token: '256f687c6225aa5d6ee50c3d68120c4c',
            apiUrl: 'https://localhost.ieeeesassadasasa',
          },
        ],
      },
    },
  },
};

export const integrationToDestroy = {
  id: '37',
  type: 'HTTP',
  active: true,
  name: 'Test 5',
  url: 'http://127.0.0.1:3000/h5bp/html5-boilerplate/alerts/notify/test-5/d4875758e67334f3.json',
  token: '89eb01df471d990ff5162a1c640408cf',
  apiUrl: null,
};

export const destroyIntegrationResponse = {
  data: {
    httpIntegrationDestroy: {
      errors: [],
      integration: {
        id: '37',
        type: 'HTTP',
        active: true,
        name: 'Test 5',
        url:
          'http://127.0.0.1:3000/h5bp/html5-boilerplate/alerts/notify/test-5/d4875758e67334f3.json',
        token: '89eb01df471d990ff5162a1c640408cf',
        apiUrl: null,
        payloadExample: '{"field": "value"}',
        payloadAttributeMappings: [],
        payloadAlertFields: [],
      },
    },
  },
};

export const destroyIntegrationResponseWithErrors = {
  data: {
    httpIntegrationDestroy: {
      errors: ['Houston, we have a problem'],
      integration: {
        id: '37',
        type: 'HTTP',
        active: true,
        name: 'Test 5',
        url:
          'http://127.0.0.1:3000/h5bp/html5-boilerplate/alerts/notify/test-5/d4875758e67334f3.json',
        token: '89eb01df471d990ff5162a1c640408cf',
        apiUrl: null,
        payloadExample: '{"field": "value"}',
        payloadAttributeMappings: [],
        payloadAlertFields: [],
      },
    },
  },
};
