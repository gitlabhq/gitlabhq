import {
  TIMESTAMP_TYPE_CREATED_AT,
  TIMESTAMP_TYPE_UPDATED_AT,
} from '~/vue_shared/components/resource_lists/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { SORT_CREATED_AT, SORT_UPDATED_AT, DEFAULT_ORGANIZATION_ID } from './constants';

export const isDefaultOrganization = (organization) =>
  getIdFromGraphQLId(organization.id) === DEFAULT_ORGANIZATION_ID;

export const timestampType = (sortName) => {
  const SORT_MAP = {
    [SORT_CREATED_AT]: TIMESTAMP_TYPE_CREATED_AT,
    [SORT_UPDATED_AT]: TIMESTAMP_TYPE_UPDATED_AT,
  };

  return SORT_MAP[sortName] || TIMESTAMP_TYPE_CREATED_AT;
};
