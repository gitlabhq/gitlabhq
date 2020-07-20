const glob = require('glob');
const prettier = require('prettier');
const fs = require('fs');
const { getStagedFiles } = require('./frontend_script_utils');

const matchExtensions = ['js', 'vue', 'graphql'];

// This will improve glob performance by excluding certain directories.
// The .prettierignore file will also be respected, but after the glob has executed.
const globIgnore = ['**/node_modules/**', 'vendor/**', 'public/**'];

const readFileAsync = (file, options) =>
  new Promise((resolve, reject) => {
    fs.readFile(file, options, function(err, data) {
      if (err) reject(err);
      else resolve(data);
    });
  });

const writeFileAsync = (file, data, options) =>
  new Promise((resolve, reject) => {
    fs.writeFile(file, data, options, function(err) {
      if (err) reject(err);
      else resolve();
    });
  });

const mode = process.argv[2] || 'check';
const shouldSave = mode === 'save' || mode === 'save-all';
const allFiles = mode === 'check-all' || mode === 'save-all';
let globDir = process.argv[3] || '';
if (globDir && globDir.charAt(globDir.length - 1) !== '/') globDir += '/';

console.log(
  `Loading all ${allFiles ? '' : 'staged '}files ${globDir ? `within ${globDir} ` : ''}...`,
);

const globPatterns = matchExtensions.map(ext => `${globDir}**/*.${ext}`);
const matchedFiles = allFiles
  ? glob.sync(`{${globPatterns.join(',')}}`, { ignore: globIgnore })
  : getStagedFiles(globPatterns);
const matchedCount = matchedFiles.length;

if (!matchedCount) {
  console.log('No files found to process with prettier');
  process.exit(0);
}

let didWarn = false;
let passedCount = 0;
let failedCount = 0;
let ignoredCount = 0;

console.log(`${shouldSave ? 'Updating' : 'Checking'} ${matchedCount} file(s)`);

const fixCommand = `yarn prettier-${allFiles ? 'all' : 'staged'}-save`;
const warningMessage = `
===============================
GitLab uses Prettier to format all JavaScript code.
Please format each file listed below or run "${fixCommand}"
===============================
`;

const checkFileWithOptions = (filePath, options) =>
  readFileAsync(filePath, 'utf8').then(input => {
    if (shouldSave) {
      const output = prettier.format(input, options);
      if (input === output) {
        passedCount += 1;
      } else {
        return writeFileAsync(filePath, output, 'utf8').then(() => {
          console.log(`Prettified : ${filePath}`);
          failedCount += 1;
        });
      }
    } else {
      if (prettier.check(input, options)) {
        passedCount += 1;
      } else {
        if (!didWarn) {
          // \x1b[31m  make text red
          // \x1b[1m   make text bold
          // %s        warningMessage
          // \x1b[0m   reset text color (so logs after aren't red)
          const redBoldText = '\x1b[1m\x1b[31;1m%s\x1b[0m';
          console.log(redBoldText, warningMessage);
          didWarn = true;
        }
        console.log(`yarn prettier --write ${filePath}`);
        failedCount += 1;
      }
    }
  });

const checkFileWithPrettierConfig = filePath =>
  prettier
    .getFileInfo(filePath, { ignorePath: '.prettierignore' })
    .then(({ ignored, inferredParser }) => {
      if (ignored || !inferredParser) {
        ignoredCount += 1;
        return;
      }
      return prettier.resolveConfig(filePath).then(fileOptions => {
        const options = { ...fileOptions, parser: inferredParser };
        return checkFileWithOptions(filePath, options);
      });
    });

Promise.all(matchedFiles.map(checkFileWithPrettierConfig))
  .then(() => {
    const failAction = shouldSave ? 'fixed' : 'failed';
    console.log(
      `\nSummary:\n  ${matchedCount} files processed (${passedCount} passed, ${failedCount} ${failAction}, ${ignoredCount} ignored)\n`,
    );

    if (didWarn) process.exit(1);
  })
  .catch(e => {
    console.log(`\nAn error occurred while processing files with prettier: ${e.message}\n`);
    process.exit(1);
  });
