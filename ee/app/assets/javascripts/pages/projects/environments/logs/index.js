import KubernetesLogs from '../../../../kubernetes_logs';

document.addEventListener('DOMContentLoaded', () => {
  const kubernetesLogContainer = document.querySelector('.js-kubernetes-logs');
  const kubernetesLog = new KubernetesLogs(kubernetesLogContainer);

  kubernetesLog.getPodLogs();
});
