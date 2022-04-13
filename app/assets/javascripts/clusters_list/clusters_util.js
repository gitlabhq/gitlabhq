export function generateAgentRegistrationCommand(agentToken, kasAddress) {
  return `helm repo add gitlab https://charts.gitlab.io
helm repo update
helm upgrade --install gitlab-agent gitlab/gitlab-agent \\
    --namespace gitlab-agent \\
    --create-namespace \\
    --set config.token=${agentToken} \\
    --set config.kasAddress=${kasAddress}`;
}

export function getAgentConfigPath(clusterAgentName) {
  return `.gitlab/agents/${clusterAgentName}`;
}
