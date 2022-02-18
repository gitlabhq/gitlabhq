import $ from 'jquery';
import axios from '~/lib/utils/axios_utils';

describe('Mock auto-injection', () => {
  describe('mocks', () => {
    let failMock;
    beforeEach(() => {
      failMock = jest.spyOn(global, 'fail').mockImplementation();
    });

    it('~/lib/utils/axios_utils', async () => {
      await expect(axios.get('http://gitlab.com')).rejects.toThrow('Unexpected unmocked request');

      expect(failMock).toHaveBeenCalledTimes(1);
    });

    it('jQuery.ajax()', () => {
      expect($.ajax).toThrow('Unexpected unmocked');
      expect(failMock).toHaveBeenCalledTimes(1);
    });
  });
});
