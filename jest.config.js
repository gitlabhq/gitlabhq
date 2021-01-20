const baseConfig = require('./jest.config.base');

module.exports = {
  ...baseConfig('spec/frontend'),
};

const karmaTestFile = process.argv.find((arg) => arg.includes('spec/javascripts/'));
if (karmaTestFile) {
  console.error(`
Files in spec/javascripts/ and ee/spec/javascripts need to be run with Karma.
Please use the following command instead:

yarn karma -f ${karmaTestFile}

`);
  process.exit(1);
}
