import { STATUS_ACKNOWLEDGED } from '~/sidebar/constants';
import { getStatusLabel } from '~/sidebar/utils';

describe('EscalationUtils', () => {
  describe('getStatusLabel', () => {
    it('returns a label when provided with a valid status', () => {
      const label = getStatusLabel(STATUS_ACKNOWLEDGED);

      expect(label).toEqual('Acknowledged');
    });

    it("returns 'None' when status is null", () => {
      const label = getStatusLabel(null);

      expect(label).toEqual('None');
    });
  });
});
