const { IS_PRODUCTION } = require('../webpack.constants');

const boolEnv = (value) => {
  if (value === 'true') return true;
  if (value === 'false') return false;
  return undefined;
};

let SOURCEMAPS = boolEnv(process.env.FE_SOURCEMAPS);
let HASHED_CHUNKS = boolEnv(process.env.FE_HASHED_CHUNKS);
const COMPRESSION = boolEnv(process.env.FE_COMPRESSION);
const MINIFY = boolEnv(process.env.FE_MINIFY);

if (boolEnv(process.env.FE_WEBPACK_REPORT)) {
  SOURCEMAPS = false;
  HASHED_CHUNKS = false;
}

let DEVTOOL = IS_PRODUCTION ? 'source-map' : 'cheap-module-source-map';
if (SOURCEMAPS === false) {
  DEVTOOL = false;
}

const RSDOCTOR = boolEnv(process.env.RSDOCTOR) === true;
const RSDOCTOR_LEAN =
  process.env.RSDOCTOR_OUTPUT === 'json' || boolEnv(process.env.FE_RSDOCTOR_LITE) === true;

module.exports = { DEVTOOL, HASHED_CHUNKS, COMPRESSION, MINIFY, RSDOCTOR, RSDOCTOR_LEAN };
