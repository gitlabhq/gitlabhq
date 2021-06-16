import initVariableList from '~/ci_variable_list';
import GroupRunnersFilteredSearchTokenKeys from '~/filtered_search/group_runners_filtered_search_token_keys';
import initSharedRunnersForm from '~/group_settings/mount_shared_runners';
import { FILTERED_SEARCH } from '~/pages/constants';
import initFilteredSearch from '~/pages/search/init_filtered_search';
import { initRunnerAwsDeployments } from '~/pages/shared/mount_runner_aws_deployments';
import { initInstallRunner } from '~/pages/shared/mount_runner_instructions';
import initSettingsPanels from '~/settings_panels';

// Initialize expandable settings panels
initSettingsPanels();

initFilteredSearch({
  page: FILTERED_SEARCH.ADMIN_RUNNERS,
  filteredSearchTokenKeys: GroupRunnersFilteredSearchTokenKeys,
  anchor: FILTERED_SEARCH.GROUP_RUNNERS_ANCHOR,
  useDefaultState: false,
});

initSharedRunnersForm();
initVariableList();

initInstallRunner();
initRunnerAwsDeployments();
