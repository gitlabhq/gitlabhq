const path = require('path');
const packageJson = require(path.join(process.cwd(), 'package.json'));
const blockedDependencies = packageJson.blockedDependencies || {};
const dependencies = packageJson.dependencies;
const devDependencies = packageJson.devDependencies;
const blockedDependenciesNames = Object.keys(blockedDependencies);
const blockedDependenciesFound = blockedDependenciesNames.filter(
  blockedDependency => dependencies[blockedDependency] || devDependencies[blockedDependency],
);

if (blockedDependenciesFound.length) {
  console.log('The following package.json dependencies are not allowed:');

  blockedDependenciesFound.forEach(blockedDependency => {
    const infoLink = blockedDependencies[blockedDependency];

    console.log(`- ${blockedDependency}: See ${infoLink} for more information.`);
  });

  process.exit(-1);
}
