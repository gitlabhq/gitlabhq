import issuableInitBulkUpdateSidebar from '~/issuable_bulk_update_sidebar/issuable_init_bulk_update_sidebar';

export default class IssuableIndex {
  constructor(pagePrefix = 'issuable_') {
    issuableInitBulkUpdateSidebar.init(pagePrefix);
  }
}
