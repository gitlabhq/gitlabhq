/* eslint-disable class-methods-use-this */
import FilteredSearchManager from '~/filtered_search/filtered_search_manager';
import IssuesFilteredSearchTokenKeysEE from 'ee/filtered_search/issues_filtered_search_token_keys';

const AUTHOR_PARAM_KEY = 'author_username';

export default class FilteredSearchServiceDesk extends FilteredSearchManager {
  constructor(supportBotData) {
    super({
      page: 'service_desk',
      filteredSearchTokenKeys: IssuesFilteredSearchTokenKeysEE,
    });

    this.supportBotData = supportBotData;
  }

  canEdit(tokenName) {
    return tokenName !== 'author';
  }

  modifyUrlParams(paramsArray) {
    const supportBotParamPair = `${AUTHOR_PARAM_KEY}=${this.supportBotData.username}`;
    const onlyValidParams = paramsArray.filter(param => param.indexOf(AUTHOR_PARAM_KEY) === -1);

    // unshift ensures author param is always first token element
    onlyValidParams.unshift(supportBotParamPair);

    return onlyValidParams;
  }
}
