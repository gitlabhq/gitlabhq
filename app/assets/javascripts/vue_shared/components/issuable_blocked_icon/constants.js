import { issuableTypes } from '~/boards/constants';
import blockingIssuesQuery from './graphql/blocking_issues.query.graphql';
import blockingEpicsQuery from './graphql/blocking_epics.query.graphql';

export const blockingIssuablesQueries = {
  [issuableTypes.issue]: {
    query: blockingIssuesQuery,
  },
  [issuableTypes.epic]: {
    query: blockingEpicsQuery,
  },
};
