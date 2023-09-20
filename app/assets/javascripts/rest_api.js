export * from './api/groups_api';
export * from './api/projects_api';
export * from './api/user_api';
export * from './api/markdown_api';
export * from './api/bulk_imports_api';
export * from './api/namespaces_api';
export * from './api/tags_api';
export * from './api/alert_management_alerts_api';
export * from './api/harbor_registry';
export * from './api/environments_api';
export * from './api/application_settings_api';

// Note: It's not possible to spy on methods imported from this file in
// Jest tests.
// As a workaround, in Jest tests, import the methods from the file
// in which they are defined:
//
// import * as UserApi from '~/api/user_api';
// vs...
// import * as UserApi from '~/rest_api';
//
// // This will only work with option #2 above.
// jest.spyOn(UserApi, 'getUsers')
