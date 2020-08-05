import { __ } from '~/locale';

export default IssuableTokenKeys => {
  const draftToken = {
    token: {
      formattedKey: __('Draft'),
      key: 'draft',
      type: 'string',
      param: '',
      symbol: '',
      icon: 'admin',
      tag: __('Yes or No'),
      lowercaseValueOnSubmit: true,
      capitalizeTokenValue: true,
    },
    conditions: [
      {
        url: 'wip=yes',
        // eslint-disable-next-line @gitlab/require-i18n-strings
        replacementUrl: 'draft=yes',
        tokenKey: 'draft',
        value: __('Yes'),
        operator: '=',
      },
      {
        url: 'wip=no',
        // eslint-disable-next-line @gitlab/require-i18n-strings
        replacementUrl: 'draft=no',
        tokenKey: 'draft',
        value: __('No'),
        operator: '=',
      },
      {
        url: 'not[wip]=yes',
        replacementUrl: 'not[draft]=yes',
        tokenKey: 'draft',
        value: __('Yes'),
        operator: '!=',
      },
      {
        url: 'not[wip]=no',
        replacementUrl: 'not[draft]=no',
        tokenKey: 'draft',
        value: __('No'),
        operator: '!=',
      },
    ],
  };

  IssuableTokenKeys.tokenKeys.push(draftToken.token);
  IssuableTokenKeys.tokenKeysWithAlternative.push(draftToken.token);
  IssuableTokenKeys.conditions.push(...draftToken.conditions);

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
