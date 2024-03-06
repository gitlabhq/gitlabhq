const paths = [];
const allModules = {};

const prefixes = {
  CE: '../pages/',
  EE: '../../../../ee/app/assets/javascripts/pages/',
  JH: '../../../../jh/app/assets/javascripts/pages/',
};

const editionExcludes = {
  JH: [],
  EE: [prefixes.JH],
  CE: [prefixes.EE, prefixes.JH],
};

const runWithExcludes = (edition) => {
  const prefix = prefixes[edition];
  const excludes = editionExcludes[edition];
  paths.forEach((path) => {
    const hasDuplicateEntrypoint = excludes.some(
      (editionPrefix) => `${editionPrefix}${path}` in allModules,
    );
    if (!hasDuplicateEntrypoint) allModules[`${prefix}${path}`]?.();
  });
};

let pathsPopulated = false;

const populatePaths = () => {
  if (pathsPopulated) return;
  paths.push(
    ...document
      .querySelector('meta[name="controller-path"]')
      .content.split('/')
      .map((part, index, arr) => `${[...arr.slice(0, index), part].join('/')}/index.js`),
  );
  pathsPopulated = true;
};

export const runModules = (modules, edition) => {
  populatePaths();
  Object.assign(allModules, modules);
  // wait before all modules have been collected to exclude duplicates between CE and EE\JH
  // <script> runs as a macrotask, can't schedule with promises here
  requestAnimationFrame(() => {
    runWithExcludes(edition);
  });
};
