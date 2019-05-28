module.exports = {
  source: {
    include: ['app/assets/javascripts/'],
  },
  opts: {
    template: 'node_modules/docdash',
    destination: 'jsdoc/',
    recurse: true,
  },
  docdash: {
    search: true,
    static: true,
  },
};
