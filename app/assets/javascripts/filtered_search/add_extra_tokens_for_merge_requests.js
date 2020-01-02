import { __ } from '~/locale';

export default IssuableTokenKeys => {
  const wipToken = {
    formattedKey: __('WIP'),
    key: 'wip',
    type: 'string',
    param: '',
    symbol: '',
    icon: 'admin',
    tag: __('Yes or No'),
    lowercaseValueOnSubmit: true,
    uppercaseTokenName: true,
    capitalizeTokenValue: true,
  };

  IssuableTokenKeys.tokenKeys.push(wipToken);
  IssuableTokenKeys.tokenKeysWithAlternative.push(wipToken);

  const targetBranchToken = {
    formattedKey: __('Target-Branch'),
    key: 'target-branch',
    type: 'string',
    param: '',
    symbol: '',
    icon: 'arrow-right',
    tag: 'branch',
  };

  IssuableTokenKeys.tokenKeys.push(targetBranchToken);
  IssuableTokenKeys.tokenKeysWithAlternative.push(targetBranchToken);
};
