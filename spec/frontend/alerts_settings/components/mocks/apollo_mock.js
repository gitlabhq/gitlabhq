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
      id: '1',
      alertManagementIntegrations: {
        nodes: [
          {
            __typename: 'AlertManagementIntegration',
            id: '37',
            type: 'HTTP',
            active: true,
            name: 'Test 5',
            url: 'http://127.0.0.1:3000/h5bp/html5-boilerplate/alerts/notify/test-5/d4875758e67334f3.json',
            token: '89eb01df471d990ff5162a1c640408cf',
            apiUrl: null,
          },
          {
            __typename: 'AlertManagementIntegration',
            id: '41',
            type: 'HTTP',
            active: true,
            name: 'Test 9999',
            url: 'http://127.0.0.1:3000/h5bp/html5-boilerplate/alerts/notify/test-9999/b78a566e1776cfc2.json',
            token: 'f7579aa03844e07af3b1f0fca3f79f81',
            apiUrl: null,
          },
          {
            __typename: 'AlertManagementIntegration',
            id: '40',
            type: 'HTTP',
            active: true,
            name: 'Test 6',
            url: 'http://127.0.0.1:3000/h5bp/html5-boilerplate/alerts/notify/test-6/3e828ae28a240222.json',
            token: '6536102a607a5dd74fcdde921f2349ee',
            apiUrl: null,
          },
          {
            __typename: 'AlertManagementIntegration',
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
  __typename: 'AlertManagementIntegration',
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
        __typename: 'AlertManagementHttpIntegration',
        id: '37',
        type: 'HTTP',
        active: true,
        name: 'Test 5',
        url: 'http://127.0.0.1:3000/h5bp/html5-boilerplate/alerts/notify/test-5/d4875758e67334f3.json',
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
        url: 'http://127.0.0.1:3000/h5bp/html5-boilerplate/alerts/notify/test-5/d4875758e67334f3.json',
        token: '89eb01df471d990ff5162a1c640408cf',
        apiUrl: null,
        payloadExample: '{"field": "value"}',
        payloadAttributeMappings: [],
        payloadAlertFields: [],
      },
    },
  },
};

export const prometheusIntegrationsList = {
  data: {
    project: {
      id: '1',
      alertManagementIntegrations: {
        nodes: [
          {
            __typename: 'AlertManagementIntegration',
            id: 'gid://gitlab/AlertManagement::HttpIntegration/7',
            type: 'HTTP',
            active: true,
            name: 'test',
            url: 'http://192.168.1.152:3000/root/autodevops/alerts/notify/test/eddd36969b2d3d6a.json',
            token: '7eb24af194116411ec8d66b58c6b0d2e',
            apiUrl: null,
          },
          {
            __typename: 'AlertManagementIntegration',
            id: 'gid://gitlab/AlertManagement::HttpIntegration/6',
            type: 'HTTP',
            active: false,
            name: 'test',
            url: 'http://192.168.1.152:3000/root/autodevops/alerts/notify/test/abce123.json',
            token: '8639e0ce06c731b00ee3e8dcdfd14fe0',
            apiUrl: null,
          },
          {
            __typename: 'AlertManagementIntegration',
            id: 'gid://gitlab/AlertManagement::HttpIntegration/5',
            type: 'HTTP',
            active: false,
            name: 'test',
            url: 'http://192.168.1.152:3000/root/autodevops/alerts/notify/test/bcd64c85f918a2e2.json',
            token: '5c8101533d970a55d5c105f8abff2192',
            apiUrl: null,
          },
          {
            __typename: 'AlertManagementIntegration',
            id: 'gid://gitlab/PrometheusService/12',
            type: 'PROMETHEUS',
            active: true,
            name: 'Prometheus',
            url: 'http://192.168.1.152:3000/root/autodevops/prometheus/alerts/notify.json',
            token: '0b18c37caa8fe980799b349916fe5ddf',
            apiUrl: null,
          },
        ],
      },
    },
  },
};
