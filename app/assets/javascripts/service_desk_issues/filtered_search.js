export default class FilteredSearchServiceDesk extends gl.FilteredSearchManager {
  constructor() {
    super('service_desk');

    this.cantEdit = ['author'];
  }

  canEdit(tokenName) {
    return this.cantEdit.indexOf(tokenName) === -1;
  }
}

