export const runModules = (modules, prefix) => {
  document
    .querySelector('meta[name="controller-path"]')
    .content.split('/')
    .forEach((part, index, arr) => {
      const path = `${prefix}${[...arr.slice(0, index), part].join('/')}/index.js`;
      modules[path]?.();
    });
};
