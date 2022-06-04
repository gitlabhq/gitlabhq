export function generateAgentRegistrationCommand(agentToken, kasAddress, kasVersion) {
  return `helm repo add gitlab https://charts.gitlab.io
helm repo update
helm upgrade --install gitlab-agent gitlab/gitlab-agent \\
    --namespace gitlab-agent \\
    --create-namespace \\
    --set image.tag=v${kasVersion} \\
    --set config.token=${agentToken} \\
    --set config.kasAddress=${kasAddress}`;
}

export function getAgentConfigPath(clusterAgentName) {
  return `.gitlab/agents/${clusterAgentName}`;
}
