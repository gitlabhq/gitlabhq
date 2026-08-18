import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ORGANIZATION } from '~/graphql_shared/constants';

// The organization being reconciled into does not exist yet, so it is given a placeholder ID to
// key it by in the reconciliation UI until it is created.
export const NEW_ORGANIZATION_ID = 1001;
export const NEW_ORGANIZATION_GID = convertToGraphQLId(TYPE_ORGANIZATION, NEW_ORGANIZATION_ID);
