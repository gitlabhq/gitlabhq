import { __ } from '~/locale';
import {
  TOKEN_TITLE_APPROVED_BY,
  TOKEN_TITLE_MERGE_USER,
  TOKEN_TITLE_REVIEWER,
  TOKEN_TYPE_APPROVED_BY,
  TOKEN_TYPE_MERGE_USER,
  TOKEN_TYPE_REVIEWER,
  TOKEN_TYPE_TARGET_BRANCH,
  TOKEN_TYPE_SOURCE_BRANCH,
} from '~/vue_shared/components/filtered_search_bar/constants';

export default (
  IssuableTokenKeys,
  { disableBranchFilter = false, disableEnvironmentFilter = false } = {},
) => {
  const reviewerToken = {
    formattedKey: TOKEN_TITLE_REVIEWER,
    key: TOKEN_TYPE_REVIEWER,
    type: 'string',
    param: 'username',
    symbol: '@',
    icon: 'user',
    tag: '@reviewer',
  };
  IssuableTokenKeys.tokenKeys.splice(2, 0, reviewerToken);
  IssuableTokenKeys.tokenKeysWithAlternative.splice(2, 0, reviewerToken);

  const draftToken = {
    token: {
      formattedKey: __('Draft'),
      key: 'draft',
      type: 'string',
      param: '',
      symbol: '',
      icon: 'pencil-square',
      tag: __('Yes or No'),
      lowercaseValueOnSubmit: true,
      capitalizeTokenValue: true,
      hideNotEqual: true,
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
    ],
  };

  IssuableTokenKeys.tokenKeys.push(draftToken.token);
  IssuableTokenKeys.tokenKeysWithAlternative.push(draftToken.token);
  IssuableTokenKeys.conditions.push(...draftToken.conditions);

  if (!disableBranchFilter) {
    const targetBranchToken = {
      formattedKey: __('Target-Branch'),
      key: TOKEN_TYPE_TARGET_BRANCH,
      type: 'string',
      param: '',
      symbol: '',
      icon: 'arrow-right',
      tag: 'branch',
    };

    const sourceBranchToken = {
      formattedKey: __('Source-Branch'),
      key: TOKEN_TYPE_SOURCE_BRANCH,
      type: 'string',
      param: '',
      symbol: '',
      icon: 'branch',
      tag: 'branch',
    };

    IssuableTokenKeys.tokenKeys.push(targetBranchToken, sourceBranchToken);
    IssuableTokenKeys.tokenKeysWithAlternative.push(targetBranchToken, sourceBranchToken);
  }

  const approvedToken = {
    token: {
      formattedKey: __('Approved'),
      key: 'approved',
      type: 'string',
      param: '',
      symbol: '',
      icon: 'approval',
      tag: __('Yes or No'),
      lowercaseValueOnSubmit: true,
      capitalizeTokenValue: true,
      hideNotEqual: true,
    },
    conditions: [
      {
        url: 'approved=yes',
        tokenKey: 'approved',
        value: __('Yes'),
        operator: '=',
      },
      {
        url: 'approved=no',
        tokenKey: 'approved',
        value: __('No'),
        operator: '=',
      },
    ],
  };

  if (gon.features.mrApprovedFilter) {
    IssuableTokenKeys.tokenKeys.splice(3, 0, approvedToken.token);
    IssuableTokenKeys.conditions.push(...approvedToken.conditions);
  }

  const approvedBy = {
    token: {
      formattedKey: TOKEN_TITLE_APPROVED_BY,
      key: TOKEN_TYPE_APPROVED_BY,
      type: 'array',
      param: 'usernames[]',
      symbol: '@',
      icon: 'approval',
      tag: '@approved-by',
    },
    tokenAlternative: {
      formattedKey: TOKEN_TITLE_APPROVED_BY,
      key: TOKEN_TYPE_APPROVED_BY,
      type: 'string',
      param: 'usernames',
      symbol: '@',
    },
    condition: [
      {
        url: 'approved_by_usernames[]=None',
        tokenKey: TOKEN_TYPE_APPROVED_BY,
        value: __('None'),
        operator: '=',
      },
      {
        url: 'not[approved_by_usernames][]=None',
        tokenKey: TOKEN_TYPE_APPROVED_BY,
        value: __('None'),
        operator: '!=',
      },
      {
        url: 'approved_by_usernames[]=Any',
        tokenKey: TOKEN_TYPE_APPROVED_BY,
        value: __('Any'),
        operator: '=',
      },
      {
        url: 'not[approved_by_usernames][]=Any',
        tokenKey: TOKEN_TYPE_APPROVED_BY,
        value: __('Any'),
        operator: '!=',
      },
    ],
  };

  const tokenPosition = gon.features.mrApprovedFilter ? 4 : 3;
  IssuableTokenKeys.tokenKeys.splice(tokenPosition, 0, approvedBy.token);
  IssuableTokenKeys.tokenKeysWithAlternative.splice(
    tokenPosition,
    0,
    ...[approvedBy.token, approvedBy.tokenAlternative],
  );
  IssuableTokenKeys.conditions.push(...approvedBy.condition);

  const mergeUserToken = {
    formattedKey: TOKEN_TITLE_MERGE_USER,
    key: TOKEN_TYPE_MERGE_USER,
    type: 'string',
    param: 'username',
    symbol: '@',
    icon: 'merge',
    tag: '@merge_user',
    hideNotEqual: true,
  };
  IssuableTokenKeys.tokenKeys.splice(3, 0, mergeUserToken);
  IssuableTokenKeys.tokenKeysWithAlternative.splice(3, 0, mergeUserToken);

  if (!disableEnvironmentFilter) {
    const environmentToken = {
      formattedKey: __('Environment'),
      key: 'environment',
      type: 'string',
      param: '',
      symbol: '',
      icon: 'environment',
      tag: 'environment',
    };

    const deployedBeforeToken = {
      formattedKey: __('Deployed-before'),
      key: 'deployed-before',
      type: 'string',
      param: '',
      symbol: '',
      icon: 'clock',
      tag: 'deployed_before',
    };

    const deployedAfterToken = {
      formattedKey: __('Deployed-after'),
      key: 'deployed-after',
      type: 'string',
      param: '',
      symbol: '',
      icon: 'clock',
      tag: 'deployed_after',
    };

    IssuableTokenKeys.tokenKeys.push(environmentToken, deployedBeforeToken, deployedAfterToken);

    IssuableTokenKeys.tokenKeysWithAlternative.push(
      environmentToken,
      deployedBeforeToken,
      deployedAfterToken,
    );
  }
};
