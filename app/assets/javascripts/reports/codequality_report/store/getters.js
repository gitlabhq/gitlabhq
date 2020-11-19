import { LOADING, ERROR, SUCCESS } from '../../constants';
import { sprintf, __, s__, n__ } from '~/locale';
import { spriteIcon } from '~/lib/utils/common_utils';

export const hasCodequalityIssues = state =>
  Boolean(state.newIssues?.length || state.resolvedIssues?.length);

export const codequalityStatus = state => {
  if (state.isLoading) {
    return LOADING;
  }
  if (state.hasError) {
    return ERROR;
  }

  return SUCCESS;
};

export const codequalityText = state => {
  const { newIssues, resolvedIssues } = state;
  const text = [];

  if (!newIssues.length && !resolvedIssues.length) {
    text.push(s__('ciReport|No changes to code quality'));
  } else {
    text.push(s__('ciReport|Code quality'));

    if (resolvedIssues.length) {
      text.push(n__(' improved on %d point', ' improved on %d points', resolvedIssues.length));
    }

    if (newIssues.length && resolvedIssues.length) {
      text.push(__(' and'));
    }

    if (newIssues.length) {
      text.push(n__(' degraded on %d point', ' degraded on %d points', newIssues.length));
    }
  }

  return text.join('');
};

export const codequalityPopover = state => {
  if (state.headPath && !state.basePath) {
    return {
      title: s__('ciReport|Base pipeline codequality artifact not found'),
      content: sprintf(
        s__('ciReport|%{linkStartTag}Learn more about codequality reports %{linkEndTag}'),
        {
          linkStartTag: `<a href="${state.helpPath}" target="_blank" rel="noopener noreferrer">`,
          linkEndTag: `${spriteIcon('external-link', 's16')}</a>`,
        },
        false,
      ),
    };
  }
  return {};
};
