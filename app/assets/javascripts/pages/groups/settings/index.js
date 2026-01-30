import initRevokeButton from '~/deploy_tokens/init_revoke_button';
import initSearchSettings from '~/search_settings';
import initDeployTokens from '~/deploy_tokens';
import { initWebBasedCommitSigningSettings } from '~/groups/settings/init_web_based_commit_signing_settings';

initWebBasedCommitSigningSettings();
initDeployTokens();
initSearchSettings();
initRevokeButton();
