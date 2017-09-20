const Promise = require('bluebird');
const path = require('path');
const fs = require('fs-extra');
const uncss = require('uncss');

const outputFile = Promise.promisify(fs.outputFile);

// Find `<script(.*?)<\/script>` and replace with nothing
// In `fixtures/pages`



function removeDisassociatedComments(str) {
  return str.replace(/\/\*(.*?)\*\/\n($|\/\*(.*?)\*\/)\n/gm, '');
}


const pagesDirectory = '/Users/eric/Documents/gitlab/gitlab-development-kit/gitlab/fixtures/pages/';

const files = [
  //path.join(pagesDirectory, 'Admin Broadcast Messages Live preview a customized broadcast message.html'),
  //path.join(pagesDirectory, 'Commits CI commit status is Ci Build when logged as reporter Renders header.html'),
  //path.join(pagesDirectory, 'Visual tokens editing assignee token makes value editable.html'),
  /* */
  ...fs.readdirSync(pagesDirectory).map((file) => {
    return path.join(pagesDirectory, file);
  })
  /* */
];

console.log(`Looking over ${files.length} files`);


const options = {
  report: true,
  stylesheets: [
    //'application-2abaf6ae8d375c7b1fad9dfa885d5da1b6ee69d983bd1d36a6699c880b7ca506.css',
    path.join(pagesDirectory, 'application-2abaf6ae8d375c7b1fad9dfa885d5da1b6ee69d983bd1d36a6699c880b7ca506.css')
  ],
  cacheDirectory: 'fixtures/pages/cache',
  concurrency: 10
};

uncss(files, options, (err, usedCss, report) => {
  if (err) {
    console.log('err', err, err.stack);
    return;
  }

  // TODO: Would be best to run this through a PostCSS plugin again and
  // remove any comment not above a rule or any at-rule with only comments inside
  //const resultantUsedCss = removeDisassociatedComments(usedCss);

  Promise.all([
    outputFile('output/raw-report3.json', JSON.stringify(report.selectors, null, 2)),
    //outputFile('output/raw-report3.json', report),
    //outputFile('output/used.css', resultantUsedCss)
  ])
    .then(() => {
      console.log('report saved to disk!');
    })
    .catch((err) => {
      console.log('Problem saving report', err, err.stack);
    });
});
