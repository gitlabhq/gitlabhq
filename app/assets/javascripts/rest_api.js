export * from './api/groups_api';
export * from './api/projects_api';
export * from './api/user_api';
export * from './api/markdown_api';

// Note: It's not possible to spy on methods imported from this file in
// Jest tests. See https://stackoverflow.com/a/53307822/1063392.
// As a workaround, in Jest tests, import the methods from the file
// in which they are defined:
//
// import * as UserApi from '~/api/user_api';
// vs...
// import * as UserApi from '~/rest_api';
//
// // This will only work with option #2 above.
// jest.spyOn(UserApi, 'getUsers')
