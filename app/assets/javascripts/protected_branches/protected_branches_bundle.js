// require everything else in this directory
function requireAll(context) { return context.keys().map(context); }
requireAll(require.context('.', false, /^\.\/(?!protected_branches_bundle).*\.(js|es6)$/));
