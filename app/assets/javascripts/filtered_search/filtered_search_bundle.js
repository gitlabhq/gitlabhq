function requireAll(context) { return context.keys().map(context); }

requireAll(require.context('./', true, /^\.\/(?!filtered_search_bundle).*\.(js|es6)$/));
