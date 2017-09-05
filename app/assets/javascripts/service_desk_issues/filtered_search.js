/* eslint-disable class-methods-use-this */

export default class FilteredSearchServiceDesk extends gl.FilteredSearchManager {
  constructor() {
    super('service_desk');

    this.supportBotAttrs = JSON.parse(
      document.querySelector('.service-desk-issues').dataset.supportBot,
    );
  }

  customRemovalValidator(token) {
    const tokenValue = token.querySelector('.value-container');

    return tokenValue ?
      tokenValue.getAttribute('data-original-value') !== `@${this.supportBotAttrs.username}` : true;
  }

  canEdit(tokenName) {
    return tokenName !== 'author';
  }

  modifyUrlParams(paramsArray) {
    const authorParamKey = 'author_username';
    const supportBotParamPair = `${authorParamKey}=${this.supportBotAttrs.username}`;
    const onlyValidParams = paramsArray.filter(param => param.indexOf(authorParamKey) === -1);

    // unshift ensures author param is always first token element
    onlyValidParams.unshift(supportBotParamPair);

    return onlyValidParams;
  }
}

