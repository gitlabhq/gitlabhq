import axios from '../lib/utils/axios_utils';
import { buildApiUrl } from './api_utils';

const JIRA_CONNECT_SUBSCRIPTIONS_PATH = '/api/:version/integrations/jira_connect/subscriptions';

export function addJiraConnectSubscription(namespacePath, { jwt, accessToken }) {
  const url = buildApiUrl(JIRA_CONNECT_SUBSCRIPTIONS_PATH);

  return axios.post(
    url,
    {
      jwt,
      namespace_path: namespacePath,
    },
    {
      headers: {
        Authorization: `Bearer ${accessToken}`, // eslint-disable-line @gitlab/require-i18n-strings
      },
    },
  );
}
