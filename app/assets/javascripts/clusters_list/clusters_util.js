export function generateAgentRegistrationCommand({ name, token, version, address }) {
  return `helm repo add gitlab https://charts.gitlab.io
helm repo update
helm upgrade --install ${name} gitlab/gitlab-agent \\
    --namespace gitlab-agent \\
    --create-namespace \\
    --set image.tag=v${version} \\
    --set config.token=${token} \\
    --set config.kasAddress=${address}`;
}

export function getAgentConfigPath(clusterAgentName) {
  return `.gitlab/agents/${clusterAgentName}`;
}
