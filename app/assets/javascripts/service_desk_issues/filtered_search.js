export default class FilteredSearchServiceDesk extends gl.FilteredSearchManager {
  constructor() {
    super('service_desk');
  }

  customRemovalValidator(token) {
    return token.querySelector('.value-container').getAttribute('data-original-value') !== '@support-bot';
  };

  canEdit(tokenName) {
    return tokenName !== 'author';
  }

  modifyUrlParams(paramsArray) {
    const paramKey = 'author_username';
    // FIXME: Need to grab the value from a data attribute
    const supportBotParamPair = `${paramKey}=support-bot`;

    return paramsArray.map((param) => {
      return param.indexOf(paramKey) !== -1 ? param : supportBotParamPair;
    });
  }
}

