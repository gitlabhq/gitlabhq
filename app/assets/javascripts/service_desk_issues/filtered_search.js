export default class FilteredSearchServiceDesk extends gl.FilteredSearchManager {
  constructor() {
    super('service_desk');

    this.cantEdit = ['author'];
    this.bindCustomCondition();
  }

  bindCustomCondition() {
    this.customRemovalValidator = function(token) {
      const originalValue = token.querySelector('.value-container').getAttribute('data-original-value');
      return originalValue !== '@support-bot';
    };
  }

  canEdit(tokenName) {
    return this.cantEdit.indexOf(tokenName) === -1;
  }

  modifyUrlParams(paramsArray) {
    const support_bot_param = 'author_username=support-bot';
    let replaced = false;

    const modified = paramsArray.map((param) => {
      const author_index = param.indexOf('author_username');
      if (author_index !== -1) {
        replaced = true;
        return support_bot_param;
      }
      return param;
    });

    if (!replaced) {
      modified.push(support_bot_param);
    }

    return modified;
  }
}

