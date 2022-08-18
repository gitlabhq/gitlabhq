import axios from 'axios';

export async function updatePipelineSchedule(endpoint) {
  const { url } = endpoint;

  return axios({
    method: 'PUT',
    baseURL: url,
    url: '/gitlab-org/gitlab-qa/-/pipeline_schedules/25',
    headers: {
      Accept: '*/*',
      'Content-Type': 'application/json; charset=utf-8',
    },
    data: {
      schedule: {
        description: 'bar',
        cron: '0 1 * * *',
        cron_timezone: 'UTC',
        active: true,
      },
    },
    validateStatus: (status) => {
      return status === 302;
    },
  });
}
