import {
  issuable1,
  issuable2,
  issuable3,
  issuable4,
  issuable5,
} from 'jest/issuable/components/related_issuable_mock_data';
import RelatedIssuesStore from '~/related_issues/stores/related_issues_store';

describe('RelatedIssuesStore', () => {
  let store;

  beforeEach(() => {
    store = new RelatedIssuesStore();
  });

  describe('setRelatedIssues', () => {
    it('defaults to empty array', () => {
      expect(store.state.relatedIssues).toEqual([]);
    });

    it('sets issues', () => {
      const relatedIssues = [issuable1];
      store.setRelatedIssues(relatedIssues);

      expect(store.state.relatedIssues).toEqual(relatedIssues);
    });
  });

  describe('addRelatedIssues', () => {
    it('adds related issues', () => {
      store.state.relatedIssues = [issuable1];
      store.addRelatedIssues([issuable2, issuable3]);

      expect(store.state.relatedIssues).toEqual([issuable1, issuable2, issuable3]);
    });
  });

  describe('removeRelatedIssue', () => {
    it('removes issue', () => {
      store.state.relatedIssues = [issuable1];

      store.removeRelatedIssue(issuable1);

      expect(store.state.relatedIssues).toEqual([]);
    });

    it('removes issue with multiple in store', () => {
      store.state.relatedIssues = [issuable1, issuable2];

      store.removeRelatedIssue(issuable1);

      expect(store.state.relatedIssues).toEqual([issuable2]);
    });
  });

  describe('updateIssueOrder', () => {
    it('updates issue order', () => {
      store.state.relatedIssues = [issuable1, issuable2, issuable3, issuable4, issuable5];

      expect(store.state.relatedIssues[3].id).toBe(issuable4.id);
      store.updateIssueOrder(3, 0);

      expect(store.state.relatedIssues[0].id).toBe(issuable4.id);
    });
  });

  describe('setPendingReferences', () => {
    it('defaults to empty array', () => {
      expect(store.state.pendingReferences).toEqual([]);
    });

    it('sets pending references', () => {
      const relatedIssues = [issuable1.reference];
      store.setPendingReferences(relatedIssues);

      expect(store.state.pendingReferences).toEqual(relatedIssues);
    });
  });

  describe('addPendingReferences', () => {
    it('adds a reference', () => {
      store.state.pendingReferences = [issuable1.reference];
      store.addPendingReferences([issuable2.reference, issuable3.reference]);

      expect(store.state.pendingReferences).toEqual([
        issuable1.reference,
        issuable2.reference,
        issuable3.reference,
      ]);
    });
  });

  describe('removePendingRelatedIssue', () => {
    it('removes issue', () => {
      store.state.pendingReferences = [issuable1.reference];

      store.removePendingRelatedIssue(0);

      expect(store.state.pendingReferences).toEqual([]);
    });

    it('removes issue with multiple in store', () => {
      store.state.pendingReferences = [issuable1.reference, issuable2.reference];

      store.removePendingRelatedIssue(0);

      expect(store.state.pendingReferences).toEqual([issuable2.reference]);
    });
  });
});
