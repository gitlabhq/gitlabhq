import issuableInitBulkUpdateSidebar from './issuable_init_bulk_update_sidebar';

export default class IssuableIndex {
  constructor(pagePrefix) {
    issuableInitBulkUpdateSidebar.init(pagePrefix);
  }
}
