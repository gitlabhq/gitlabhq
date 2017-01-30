function requireAll(context) { return context.keys().map(context); }

require('./approvals_store');
require('./approvals_api');

requireAll(require.context('./components', true, /^\.\/.*\.(js|es6)$/));
