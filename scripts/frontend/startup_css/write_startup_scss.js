const { writeFileSync } = require('fs');
const path = require('path');
const prettier = require('prettier');
const { PATH_STARTUP_SCSS } = require('./constants');

const buildFinalContent = (raw) => {
  const content = `// DO NOT EDIT! This is auto-generated from "yarn run generate:startup_css"
// Please see the feedback issue for more details and help:
// https://gitlab.com/gitlab-org/gitlab/-/issues/331812
@charset "UTF-8";
${raw}
@import 'startup/cloaking';
@include cloak-startup-scss(none);
`;

  // We run prettier so that there is more determinism with the generated file.
  return prettier.format(content, { parser: 'scss' });
};

const writeStartupSCSS = (name, raw) => {
  const fullPath = path.join(PATH_STARTUP_SCSS, `${name}.scss`);

  writeFileSync(fullPath, buildFinalContent(raw));

  return fullPath;
};

module.exports = { writeStartupSCSS };
