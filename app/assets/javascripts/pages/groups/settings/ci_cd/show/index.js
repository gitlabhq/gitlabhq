import initStaleRunnerCleanupSetting from 'ee_else_ce/group_settings/stale_runner_cleanup';
import { initAllowRunnerRegistrationTokenToggle } from '~/group_settings/allow_runner_registration_token_toggle';
import { initJwtCiCdJobTokenEnabledToggle } from '~/group_settings/jwt_ci_cd_job_token_enabled_toggle';

import initPipelineVariablesDefaultRole from '~/group_settings/pipeline_variables_default_role';
import initVariableList from '~/ci/ci_variable_list';
import initSharedRunnersForm from '~/group_settings/mount_shared_runners';
import initSettingsPanels from '~/settings_panels';
import initDeployTokens from '~/deploy_tokens';

// Initialize expandable settings panels
initSettingsPanels();
initDeployTokens();
initAllowRunnerRegistrationTokenToggle();
initJwtCiCdJobTokenEnabledToggle();
initSharedRunnersForm();
initStaleRunnerCleanupSetting();
initVariableList();
initPipelineVariablesDefaultRole();
