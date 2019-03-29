const fs = require('fs');
const path = require('path');

const ROOT_PATH = path.resolve(__dirname, '../..');

module.exports =
  process.env.EE !== undefined
    ? JSON.parse(process.env.EE)
    : fs.existsSync(path.join(ROOT_PATH, 'ee'));
