const glob = require('glob');
const prettier = require('prettier');
const fs = require('fs');
const path = require('path');
const prettierIgnore = require('ignore')();

const getStagedFiles = require('./frontend_script_utils').getStagedFiles;

const mode = process.argv[2] || 'check';
const shouldSave = mode === 'save' || mode === 'save-all';
const allFiles = mode === 'check-all' || mode === 'save-all';

const config = {
  patterns: ['**/*.js', '**/*.vue', '**/*.scss'],
  /*
   * The ignore patterns below are just to reduce search time with glob, as it includes the
   * folders with the most ignored assets, the actual `.prettierignore` will be used later on
   */
  ignore: ['**/node_modules/**', '**/vendor/**', '**/public/**'],
  parsers: {
    js: 'babylon',
    vue: 'vue',
    scss: 'css',
  },
};

/*
 * Unfortunately the prettier API does not expose support for `.prettierignore` files, they however
 * use the ignore package, so we do the same. We simply cannot use the glob package, because
 * gitignore style is not compatible with globs ignore style.
 */
prettierIgnore.add(
  fs
    .readFileSync(path.join(__dirname, '../../', '.prettierignore'))
    .toString()
    .trim()
    .split(/\r?\n/)
);

const availableExtensions = Object.keys(config.parsers);

console.log(`Loading ${allFiles ? 'All' : 'Staged'} Files ...`);

const stagedFiles = allFiles ? null : getStagedFiles(availableExtensions.map(ext => `*.${ext}`));

if (stagedFiles) {
  if (!stagedFiles.length || (stagedFiles.length === 1 && !stagedFiles[0])) {
    console.log('No matching staged files.');
    return;
  }
  console.log(`Matching staged Files : ${stagedFiles.length}`);
}

let didWarn = false;
let didError = false;

let files;
if (allFiles) {
  const ignore = config.ignore;
  const patterns = config.patterns;
  const globPattern = patterns.length > 1 ? `{${patterns.join(',')}}` : `${patterns.join(',')}`;
  files = glob.sync(globPattern, { ignore }).filter(f => allFiles || stagedFiles.includes(f));
} else {
  files = stagedFiles.filter(f => availableExtensions.includes(f.split('.').pop()));
}

files = prettierIgnore.filter(files);

if (!files.length) {
  console.log('No Files found to process with Prettier');
  return;
}

console.log(`${shouldSave ? 'Updating' : 'Checking'} ${files.length} file(s)`);

prettier
  .resolveConfig('.')
  .then(options => {
    console.log('Found options : ', options);
    files.forEach(file => {
      try {
        const fileExtension = file.split('.').pop();
        Object.assign(options, {
          parser: config.parsers[fileExtension],
        });

        const input = fs.readFileSync(file, 'utf8');

        if (shouldSave) {
          const output = prettier.format(input, options);
          if (output !== input) {
            fs.writeFileSync(file, output, 'utf8');
            console.log(`Prettified : ${file}`);
          }
        } else if (!prettier.check(input, options)) {
          if (!didWarn) {
            console.log(
              '\n===============================\nGitLab uses Prettier to format all JavaScript code.\nPlease format each file listed below or run "yarn prettier-staged-save"\n===============================\n'
            );
            didWarn = true;
          }
          console.log(`Prettify Manually : ${file}`);
        }
      } catch (error) {
        didError = true;
        console.log(`\n\nError with ${file}: ${error.message}`);
      }
    });

    if (didWarn || didError) {
      process.exit(1);
    }
  })
  .catch(e => {
    console.log(`Error on loading the Config File: ${e.message}`);
    process.exit(1);
  });
