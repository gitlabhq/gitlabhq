import { TYPE_EPIC, TYPE_ISSUE } from '~/issues/constants';
import blockingIssuesQuery from './graphql/blocking_issues.query.graphql';
import blockingEpicsQuery from './graphql/blocking_epics.query.graphql';

export const blockingIssuablesQueries = {
  [TYPE_ISSUE]: {
    query: blockingIssuesQuery,
  },
  [TYPE_EPIC]: {
    query: blockingEpicsQuery,
  },
};
