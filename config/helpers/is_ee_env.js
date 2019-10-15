const fs = require('fs');
const path = require('path');

const ROOT_PATH = path.resolve(__dirname, '../..');

// The `IS_GITLAB_EE` is always `string` or `nil`
// Thus the nil or empty string will result
// in using default value: true
//
// The behavior needs to be synchronised with
// lib/gitlab.rb: Gitlab.ee?
module.exports =
  fs.existsSync(path.join(ROOT_PATH, 'ee', 'app', 'models', 'license.rb')) &&
  (!process.env.IS_GITLAB_EE || JSON.parse(process.env.IS_GITLAB_EE));
