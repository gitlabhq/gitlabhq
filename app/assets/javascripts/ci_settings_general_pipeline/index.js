export const initGeneralPipelinesOptions = () => {
  const forwardDeploymentEnabledCheckbox = document.getElementById(
    'project_ci_cd_settings_attributes_forward_deployment_enabled',
  );
  const forwardDeploymentRollbackAllowedCheckbox = document.getElementById(
    'project_ci_cd_settings_attributes_forward_deployment_rollback_allowed',
  );

  if (forwardDeploymentRollbackAllowedCheckbox && forwardDeploymentEnabledCheckbox) {
    forwardDeploymentRollbackAllowedCheckbox.disabled = !forwardDeploymentEnabledCheckbox.checked;

    forwardDeploymentEnabledCheckbox.addEventListener('change', () => {
      if (!forwardDeploymentEnabledCheckbox.checked) {
        forwardDeploymentRollbackAllowedCheckbox.checked = false;
      }
      forwardDeploymentRollbackAllowedCheckbox.disabled = !forwardDeploymentEnabledCheckbox.checked;
    });
  }
};
