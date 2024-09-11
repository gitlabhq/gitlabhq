import { s__ } from '~/locale';

const translations = {
  addTokenButton: s__('DeployTokens|Create deploy token'),
  cancelTokenCreation: s__('DeployTokens|Cancel'),
  addTokenExpiryLabel: s__('DeployTokens|Expiration date (optional)'),
  addTokenExpiryDescription: s__(
    'DeployTokens|Enter an expiration date for your token. Defaults to never expire.',
  ),
  addTokenHeader: s__('DeployTokens|New deploy token'),
  addTokenDescription: s__(
    'DeployTokens|Create a new deploy token for all projects in this group. %{link_start}What are deploy tokens?%{link_end}',
  ),
  addTokenNameLabel: s__('DeployTokens|Name'),
  addTokenNameDescription: s__(
    'DeployTokens|Enter a unique name for your deploy token. Name the token gitlab-deploy-token to expose it to CI/CD jobs.',
  ),
  addTokenScopesLabel: s__('DeployTokens|Scopes (select at least one)'),
  addTokenUsernameDescription: s__(
    'DeployTokens|Enter a username for your token. Defaults to %{code_start}gitlab+deploy-token-{n}%{code_end}.',
  ),
  addTokenUsernameLabel: s__('DeployTokens|Username (optional)'),
  newTokenCopyMessage: s__('DeployTokens|Copy deploy token'),
  newProjectTokenCreated: s__('DeployTokens|Your new project deploy token has been created.'),
  newGroupTokenCreated: s__('DeployTokens|Your new group deploy token has been created.'),
  newTokenDescription: s__(
    'DeployTokens|Use this token as a password. Save it. This password can %{i_start}not%{i_end} be recovered.',
  ),
  newTokenMessage: s__('DeployTokens|Your new deploy token'),
  newTokenUsernameCopy: s__('DeployTokens|Copy username'),
  newTokenUsernameDescription: s__(
    'DeployTokens|This username supports access. %{link_start}What kind of access?%{link_end}',
  ),
  readRepositoryHelp: s__('DeployTokens|Allows read-only access to the repository.'),
  readRegistryHelp: s__('DeployTokens|Allows read-only access to registry images.'),
  writeRegistryHelp: s__(
    'DeployTokens|Allows write access to registry images. You need both read and write access to push images.',
  ),
  readPackageRegistryHelp: s__('DeployTokens|Allows read-only access to the package registry.'),
  groupWritePackageRegistryHelp: s__(
    'DeployTokens|Allows read and write access to the package registry.',
  ),
  projectWritePackageRegistryHelp: s__(
    'DeployTokens|Allows read, write and delete access to the package registry.',
  ),
  createTokenFailedAlert: s__('DeployTokens|Failed to create a new deployment token'),
};

export default translations;
