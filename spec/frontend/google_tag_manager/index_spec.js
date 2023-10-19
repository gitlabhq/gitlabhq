import { trackTrialAcceptTerms } from 'ee_else_ce/google_tag_manager';

describe('~/google_tag_manager/index', () => {
  describe('No listener events', () => {
    it('when trackTrialAcceptTerms is invoked', () => {
      expect(trackTrialAcceptTerms()).toBeUndefined();
    });
  });
});
