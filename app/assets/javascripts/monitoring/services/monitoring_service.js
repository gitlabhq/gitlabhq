import axios from '../../lib/utils/axios_utils';
import statusCodes from '../../lib/utils/http_status';
import { backOff } from '../../lib/utils/common_utils';
import { s__ } from '../../locale';

const MAX_REQUESTS = 3;

function backOffRequest(makeRequestCallback) {
  let requestCounter = 0;
  return backOff((next, stop) => {
    makeRequestCallback().then((resp) => {
      if (resp.status === statusCodes.NO_CONTENT) {
        requestCounter += 1;
        if (requestCounter < MAX_REQUESTS) {
          next();
        } else {
          stop(new Error('Failed to connect to the prometheus server'));
        }
      } else {
        stop(resp);
      }
    }).catch(stop);
  });
}

export default class MonitoringService {
  constructor({ metricsEndpoint, deploymentEndpoint, environmentsEndpoint }) {
    this.metricsEndpoint = metricsEndpoint;
    this.deploymentEndpoint = deploymentEndpoint;
    this.environmentsEndpoint = environmentsEndpoint;
  }

  getGraphsData() {
    const initialTime = 1532868277.633;

    function createValues(length = 20) {
      let values = []
      for (let i = 0; i < length; i++)  {
        const increase = i * 60
        let time = initialTime + increase
        const value = Math.random()
        values.push([
          time,
          value
        ])
      }
      return values
    }
    const values = createValues()

    const valuesWithZeroes = [
      ...values.slice(0, 4),
      [
        values[4][0],
        0
      ],
      [
        values[5][0],
        0
      ],
      ...values.slice(6)
    ];

    const valuesWithGap = [
      ...createValues().slice(1, 4),
      ...createValues().slice(6),
    ];

    const results = [
      {
        "group": "Response metrics (Custom)",
        "priority": 0,
        "metrics": [
          {
            "title": "Error Rate",
            "weight": 0,
            "y_label": "Error Rate",
            "queries": [
              {
                "query_range": "sum(backend_code:haproxy_server_http_responses_total:irate1m{tier=\"lb\", environment=\"prd\", code=\"5xx\"}) by (code,backend)",
                "unit": "errors / min",
                "label": "errors / min",
                "result": [
                  {
                    "metric": {
                      "backend": "canary_web",
                      "code": "5xx"
                    },
                    "values": valuesWithGap,
                  },
                  {
                    "metric": {
                      "backend": "https_git",
                      "code": "5xx"
                    },
                    values: values
                  },
                  {
                    "metric": {
                      "backend": "pages_http",
                      "code": "5xx"
                    },
                    values: createValues()
                  },
                  {
                    "metric": {
                      "backend": "registry",
                      "code": "5xx"
                    },
                    values: valuesWithGap
                  },
                ]
              }
            ]
          },
        ]
      }
    ];
    return Promise.resolve(results);
    return backOffRequest(() => axios.get(this.metricsEndpoint))
      .then(resp => resp.data)
      .then((response) => {
        if (!response || !response.data) {
          throw new Error(s__('Metrics|Unexpected metrics data response from prometheus endpoint'));
        }
        return response.data;
      });
  }

  getDeploymentData() {
    if (!this.deploymentEndpoint) {
      return Promise.resolve([]);
    }
    return backOffRequest(() => axios.get(this.deploymentEndpoint))
      .then(resp => resp.data)
      .then((response) => {
        if (!response || !response.deployments) {
          throw new Error(s__('Metrics|Unexpected deployment data response from prometheus endpoint'));
        }
        return response.deployments;
      });
  }

  getEnvironmentsData() {
    return axios.get(this.environmentsEndpoint)
    .then(resp => resp.data)
    .then((response) => {
      if (!response || !response.environments) {
        throw new Error(s__('Metrics|There was an error fetching the environments data, please try again'));
      }
      return response.environments;
    });
  }
}
