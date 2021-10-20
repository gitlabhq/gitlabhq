export function generateAgentRegistrationCommand(agentToken, kasAddress) {
  return `docker run --pull=always --rm \\
    registry.gitlab.com/gitlab-org/cluster-integration/gitlab-agent/cli:stable generate \\
    --agent-token=${agentToken} \\
    --kas-address=${kasAddress} \\
    --agent-version stable \\
    --namespace gitlab-kubernetes-agent | kubectl apply -f -`;
}
