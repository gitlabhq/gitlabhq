const fs = require('fs');
const path = require('path');

const ROOT_PATH = path.resolve(__dirname, '../..');

// The `FOSS_ONLY` is always `string` or `nil`
// Thus the nil or empty string will result
// in using default value: false
//
// The behavior needs to be synchronised with
// lib/gitlab.rb: Gitlab.ee?
const isFossOnly = JSON.parse(process.env.FOSS_ONLY || 'false');
module.exports =
  fs.existsSync(path.join(ROOT_PATH, 'ee', 'app', 'models', 'license.rb')) && !isFossOnly;
