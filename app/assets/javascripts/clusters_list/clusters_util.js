import { ACTIVE_CONNECTION_TIME, NAME_MAX_LENGTH } from './constants';

function getTruncatedName(name) {
  return name.substring(0, NAME_MAX_LENGTH);
}

export function generateAgentRegistrationCommand({ name, token, version, address }) {
  const versionValue = window.gon.dot_com ? '' : `\n    --set image.tag=v${version} \\`;
  return `helm repo add gitlab https://charts.gitlab.io
helm repo update
helm upgrade --install ${name} gitlab/gitlab-agent \\
    --namespace gitlab-agent-${getTruncatedName(name)} \\
    --create-namespace \\${versionValue}
    --set config.token=${token} \\
    --set config.kasAddress=${address}`;
}

export function getAgentConfigPath(clusterAgentName) {
  return `.gitlab/agents/${clusterAgentName}`;
}

export function getAgentLastContact(tokens = []) {
  let lastContact = null;
  tokens.forEach((token) => {
    const lastContactToDate = new Date(token.lastUsedAt).getTime();
    if (lastContactToDate > lastContact) {
      lastContact = lastContactToDate;
    }
  });
  return lastContact;
}

export function getAgentStatus(lastContact) {
  if (lastContact) {
    const now = new Date().getTime();
    const diff = now - lastContact;

    return diff >= ACTIVE_CONNECTION_TIME ? 'inactive' : 'active';
  }
  return 'unused';
}
