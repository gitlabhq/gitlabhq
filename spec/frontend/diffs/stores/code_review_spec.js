import { createTestingPinia } from '@pinia/testing';
import { useCodeReview } from '~/diffs/stores/code_review';

describe('CodeReview store', () => {
  beforeEach(() => {
    createTestingPinia({ stubActions: false });
  });

  describe('#setMrPath', () => {
    it('sets mr path', () => {
      useCodeReview().setMrPath('foo');
      expect(useCodeReview().mrPath).toBe('foo');
    });
  });

  describe('#restoreFromAutosave', () => {
    it('restores from autosave', () => {
      const items = ['bar'];
      useCodeReview().setMrPath('foo');
      localStorage.setItem(useCodeReview().autosaveKey, JSON.stringify(items));
      useCodeReview().restoreFromAutosave();
      expect(useCodeReview().reviewedIds.bar).toBe(true);
    });
  });

  describe('#restoreFromLegacyMrReviews', () => {
    it('restores from autosave', () => {
      const items = { bar: ['baz'] };
      useCodeReview().setMrPath('foo');
      localStorage.setItem('foo-file-reviews', JSON.stringify(items));
      useCodeReview().restoreFromLegacyMrReviews();
      expect(useCodeReview().reviewedIds.baz).toBe(true);
    });

    it('does not restore hash: values', () => {
      const items = { bar: ['hash:baz'] };
      useCodeReview().setMrPath('foo');
      localStorage.setItem('foo-file-reviews', JSON.stringify(items));
      useCodeReview().restoreFromLegacyMrReviews();
      expect(useCodeReview().reviewedIds.baz).toBe(undefined);
    });

    it('stores state', () => {
      useCodeReview().setMrPath('foo');
      localStorage.setItem('foo-file-reviews', JSON.stringify({ bar: ['baz'] }));
      useCodeReview().restoreFromLegacyMrReviews();
      const items = localStorage.getItem(useCodeReview().autosaveKey);
      expect(JSON.parse(items)).toContain('baz');
    });
  });

  describe('#setReviewed', () => {
    it('marks file as reviewed', () => {
      useCodeReview().setMrPath('foo');
      useCodeReview().setReviewed('bar', true);
      expect(useCodeReview().reviewedIds.bar).toBe(true);
    });

    it('stores state', () => {
      useCodeReview().setMrPath('foo');
      useCodeReview().setReviewed('bar', true);
      const items = localStorage.getItem(useCodeReview().autosaveKey);
      expect(JSON.parse(items)).toContain('bar');
    });
  });

  describe('#removeId', () => {
    it('removes existing ID', () => {
      useCodeReview().setMrPath('foo');
      useCodeReview().reviewedIds = { bar: true };
      useCodeReview().removeId('bar');
      expect(useCodeReview().reviewedIds.bar).toBe(undefined);
    });
  });

  describe('#autosave', () => {
    it('stores state', () => {
      useCodeReview().setMrPath('foo');
      useCodeReview().reviewedIds = { bar: true };
      useCodeReview().autosave();
      const items = localStorage.getItem(useCodeReview().autosaveKey);
      expect(JSON.parse(items)).toContain('bar');
    });

    it('clears storage', () => {
      useCodeReview().setMrPath('foo');
      useCodeReview().autosave();
      expect(localStorage.getItem(useCodeReview().autosaveKey)).toBe(null);
    });
  });

  describe('#markedAsViewedIds', () => {
    it('returns only viewed ids', () => {
      useCodeReview().setMrPath('foo');
      useCodeReview().setReviewed('bar', false);
      useCodeReview().setReviewed('baz', true);
      expect(useCodeReview().markedAsViewedIds).toMatchObject(['baz']);
    });
  });

  describe('#autosaveKey', () => {
    it('returns autosave key', () => {
      useCodeReview().setMrPath('foo');
      expect(useCodeReview().autosaveKey).toBe('code-review-foo');
    });
  });
});
