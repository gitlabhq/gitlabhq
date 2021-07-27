const fs = require('fs');
const path = require('path');
const IS_EE = require('./is_ee_env');

const ROOT_PATH = path.resolve(__dirname, '../..');

// The `FOSS_ONLY` is always `string` or `nil`
// Thus the nil or empty string will result
// in using default value: false
//
// The behavior needs to be synchronised with
// lib/gitlab.rb: Gitlab.jh?
// Since IS_EE already satisifies the conditions of not being a FOSS_ONLY.
// const isFossOnly = JSON.parse(process.env.FOSS_ONLY || 'false');
const isEEOnly = JSON.parse(process.env.EE_ONLY || 'false');
module.exports = IS_EE && !isEEOnly && fs.existsSync(path.join(ROOT_PATH, 'jh'));
