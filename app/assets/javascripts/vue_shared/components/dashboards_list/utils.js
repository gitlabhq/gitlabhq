import { NAME_FIELD, CREATED_BY_FIELD, ACTIONS_FIELD } from './constants';

// Kept out of the component so EE can gate columns behind EE-only feature flags.
export const getDashboardsListFields = () => [NAME_FIELD, CREATED_BY_FIELD, ACTIONS_FIELD];
