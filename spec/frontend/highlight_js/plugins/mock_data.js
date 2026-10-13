export const PACKAGE_JSON_FILE_TYPE = 'package_json';

export const PACKAGE_JSON_CONTENT = '{ "dependencies": { "@babel/core": "^7.18.5" } }';

export const COMPOSER_JSON_EXAMPLES = {
  packagist: '{ "require": { "composer/installers": "^1.2" } }',
  drupal: '{ "require": { "drupal/bootstrap": "3.x-dev" } }',
  withoutLink: '{ "require": { "drupal/erp_common": "dev-master" } }',
};

export const GEMSPEC_FILE_TYPE = 'gemspec';

export const GODEPS_JSON_FILE_TYPE = 'godeps_json';

export const GEMFILE_FILE_TYPE = 'gemfile';

export const PODSPEC_JSON_FILE_TYPE = 'podspec_json';

export const PODSPEC_JSON_CONTENT = `{
    "dependencies": {
        "MyCheckCore": [
        ]
    },
    "subspecs": [
      {
        "dependencies": {
          "AFNetworking/Security": [
          ]
        }
      }
    ]
  }`;

export const COMPOSER_JSON_FILE_TYPE = 'composer_json';

export const GO_SUM_FILE_TYPE = 'go_sum';
