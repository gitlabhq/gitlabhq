import $ from 'jquery';
import MockAdaptor from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import IssuableIndex from '~/issuable_index';
import issuableInitBulkUpdateSidebar from '~/issuable_init_bulk_update_sidebar';

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

  describe('resetIncomingEmailToken', () => {
    let mock;

    beforeEach(() => {
      const element = document.createElement('a');
      element.classList.add('incoming-email-token-reset');
      element.setAttribute('href', 'foo');
      document.body.appendChild(element);

      const input = document.createElement('input');
      input.setAttribute('id', 'issuable_email');
      document.body.appendChild(input);

      new IssuableIndex('issue_'); // eslint-disable-line no-new

      mock = new MockAdaptor(axios);

      mock.onPut('foo').reply(200, {
        new_address: 'testing123',
      });
    });

    afterEach(() => {
      mock.restore();
    });

    it('should send request to reset email token', done => {
      jest.spyOn(axios, 'put');
      document.querySelector('.incoming-email-token-reset').click();

      setImmediate(() => {
        expect(axios.put).toHaveBeenCalledWith('foo');
        expect($('#issuable_email').val()).toBe('testing123');

        done();
      });
    });
  });
});
