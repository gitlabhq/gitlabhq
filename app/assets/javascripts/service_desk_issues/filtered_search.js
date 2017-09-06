/* eslint-disable class-methods-use-this */

const AUTHOR_PARAM_KEY = 'author_username';

export default class FilteredSearchServiceDesk extends gl.FilteredSearchManager {
  constructor(supportBotData) {
    super('service_desk');

    this.supportBotData = supportBotData;
  }

  customRemovalValidator(token) {
    const tokenValue = token.querySelector('.value-container');

    return tokenValue ?
      tokenValue.getAttribute('data-original-value') !== `@${this.supportBotData.username}` : true;
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

