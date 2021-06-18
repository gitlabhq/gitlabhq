import issuableInitBulkUpdateSidebar from '~/issuable_bulk_update_sidebar/issuable_init_bulk_update_sidebar';
import IssuableIndex from '~/issuable_index';

describe('Issuable', () => {
  describe('initBulkUpdate', () => {
    it('should not set bulkUpdateSidebar', () => {
      new IssuableIndex('issue_'); // eslint-disable-line no-new

      expect(issuableInitBulkUpdateSidebar.bulkUpdateSidebar).toBeNull();
    });

    it('should set bulkUpdateSidebar', () => {
      const element = document.createElement('div');
      element.classList.add('issues-bulk-update');
      document.body.appendChild(element);

      new IssuableIndex('issue_'); // eslint-disable-line no-new

      expect(issuableInitBulkUpdateSidebar.bulkUpdateSidebar).toBeDefined();
    });
  });
});
