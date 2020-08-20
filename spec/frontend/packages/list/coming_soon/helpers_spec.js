import * as comingSoon from '~/packages/list/coming_soon/helpers';
import { fakeIssues, asGraphQLResponse, asViewModel } from './mock_data';

jest.mock('~/api.js');

describe('Coming Soon Helpers', () => {
  const [noLabels, acceptingMergeRequestLabel, workflowLabel] = fakeIssues;

  describe('toViewModel', () => {
    it('formats a GraphQL response correctly', () => {
      expect(comingSoon.toViewModel(asGraphQLResponse)).toEqual(asViewModel);
    });
  });

  describe('findWorkflowLabel', () => {
    it('finds a workflow label', () => {
      expect(comingSoon.findWorkflowLabel(workflowLabel.labels)).toEqual(workflowLabel.labels[0]);
    });

    it("returns undefined when there isn't one", () => {
      expect(comingSoon.findWorkflowLabel(noLabels.labels)).toBeUndefined();
    });
  });

  describe('findAcceptingContributionsLabel', () => {
    it('finds the correct label when it exists', () => {
      expect(comingSoon.findAcceptingContributionsLabel(acceptingMergeRequestLabel.labels)).toEqual(
        acceptingMergeRequestLabel.labels[0],
      );
    });

    it("returns undefined when there isn't one", () => {
      expect(comingSoon.findAcceptingContributionsLabel(noLabels.labels)).toBeUndefined();
    });
  });
});
