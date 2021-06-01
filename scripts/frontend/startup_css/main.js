const { memoize } = require('lodash');
const { OUTPUTS } = require('./constants');
const { getCSSPath } = require('./get_css_path');
const { getStartupCSS } = require('./get_startup_css');
const { log, die } = require('./utils');
const { writeStartupSCSS } = require('./write_startup_scss');

const memoizedCSSPath = memoize(getCSSPath);

const runTask = async ({ outFile, htmlPaths, cssKeys, purgeOptions = {} }) => {
  try {
    log(`Generating startup CSS for HTML files: ${htmlPaths}`);
    const generalCSS = await getStartupCSS({
      htmlPaths,
      cssPaths: cssKeys.map(memoizedCSSPath),
      purgeOptions,
    });

    log(`Writing to startup CSS...`);
    const startupCSSPath = writeStartupSCSS(outFile, generalCSS);
    log(`Finished writing to ${startupCSSPath}`);

    return {
      success: true,
      outFile,
    };
  } catch (e) {
    log(`ERROR! Unexpected error occurred while generating startup CSS for: ${outFile}`);
    log(e);

    return {
      success: false,
      outFile,
    };
  }
};

const main = async () => {
  const result = await Promise.all(OUTPUTS.map(runTask));
  const fullSuccess = result.every((x) => x.success);

  log('RESULTS:');
  log('--------');

  result.forEach(({ success, outFile }) => {
    const status = success ? '✓' : 'ⅹ';

    log(`${status}: ${outFile}`);
  });

  log('--------');

  if (fullSuccess) {
    log('Done!');
  } else {
    die('Some tasks have failed');
  }
};

main();
