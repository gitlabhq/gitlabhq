const { USE_VUE3_COMPILER, VUE_LOADER_MODULE } = require('../vue3migration/version');

const NS = 'vue-loader';
const ID = 'vue-loader-plugin';

// What differs between vue-loader 15 (Vue 2 compiler) and 17 (Vue 3 compiler).
const VUE_LOADER = USE_VUE3_COMPILER
  ? {
      paths: { pitcher: 'dist/pitcher', template: 'dist/templateLoader', index: 'dist/index' },
      needsTemplateRule: () => true,
    }
  : {
      paths: {
        pitcher: 'lib/loaders/pitcher',
        template: 'lib/loaders/templateLoader',
        index: 'lib/index',
      },
      // Its pitcher inlines the template loader, except with the Vue 2.7 compiler.
      needsTemplateRule: (context) => {
        // eslint-disable-next-line global-require -- vue-loader 15 only
        const { resolveCompiler } = require('vue-loader/lib/compiler');
        return resolveCompiler(context).is27;
      },
    };
const resolveLoader = (file) => require.resolve(`${VUE_LOADER_MODULE}/${file}`);

const PITCHER_PATH = resolveLoader(VUE_LOADER.paths.pitcher);
const TEMPLATE_LOADER_PATH = resolveLoader(VUE_LOADER.paths.template);
const VUE_LOADER_INDEX = resolveLoader(VUE_LOADER.paths.index);

// config/rspack/vue.js names the loader bare, and `vue-loader-vue3` has no prefix for the regex.
const useEntryIsVueLoader = (loader) =>
  typeof loader === 'string' &&
  (/(\/|\\|@)vue-loader/.test(loader) || loader === 'vue-loader' || loader === VUE_LOADER_MODULE);

function normaliseUse(rule) {
  if (Array.isArray(rule.use)) {
    return rule.use.map((u) => (typeof u === 'string' ? { loader: u } : { ...u }));
  }
  if (rule.use) {
    return [typeof rule.use === 'string' ? { loader: rule.use } : { ...rule.use }];
  }
  if (rule.loader) {
    return [{ loader: rule.loader, options: rule.options }];
  }
  return [];
}

function findVueRule(rules) {
  return rules.find((rule) => {
    if (!rule || rule.enforce) return false;
    const { test } = rule;
    if (test instanceof RegExp) return test.test('foo.vue');
    if (typeof test === 'function') {
      try {
        return Boolean(test('foo.vue'));
      } catch {
        return false;
      }
    }
    if (Array.isArray(test)) {
      return test.some((t) => t instanceof RegExp && t.test('foo.vue'));
    }
    return false;
  });
}

class VueLoaderPlugin {
  // eslint-disable-next-line class-methods-use-this -- webpack/rspack plugin interface
  apply(compiler) {
    const NormalModule =
      (compiler.webpack && compiler.webpack.NormalModule) ||
      // eslint-disable-next-line global-require -- fallback only when the compiler doesn't expose it
      require('@rspack/core').NormalModule;

    compiler.hooks.compilation.tap(ID, (compilation) => {
      const loaderHook = NormalModule.getCompilationHooks(compilation).loader;
      loaderHook.tap(ID, (loaderContext) => {
        // eslint-disable-next-line no-param-reassign
        loaderContext[NS] = true;
      });
    });

    const { rules } = compiler.options.module;
    const rawVueRule = findVueRule(rules);
    if (!rawVueRule) {
      throw new Error(
        '[VueLoaderPlugin] No matching rule for .vue files found. ' +
          'Ensure a root-level rule matches `.vue` and uses vue-loader.',
      );
    }

    const vueUse = normaliseUse(rawVueRule);
    const vueLoaderUse = vueUse.find((u) => useEntryIsVueLoader(u.loader));
    if (!vueLoaderUse) {
      throw new Error('[VueLoaderPlugin] The rule matching `.vue` files must use vue-loader.');
    }
    vueLoaderUse.ident = 'vue-loader-options';
    vueLoaderUse.options = vueLoaderUse.options || {};
    vueLoaderUse.options.experimentalInlineMatchResource = true;

    delete rawVueRule.loader;
    delete rawVueRule.options;
    rawVueRule.use = vueUse;

    const pitcher = {
      loader: PITCHER_PATH,
      resourceQuery: (query) => {
        if (!query) return false;
        const parsed = new URLSearchParams(query.slice(1));
        return parsed.has('vue');
      },
      options: vueLoaderUse.options,
    };

    const templateCompilerRule = {
      loader: TEMPLATE_LOADER_PATH,
      resourceQuery: (query) => {
        if (!query) return false;
        const parsed = new URLSearchParams(query.slice(1));
        return parsed.has('vue') && parsed.get('type') === 'template';
      },
      options: vueLoaderUse.options,
    };

    const vueLoaderRules = rules.filter((rule) => {
      const loader =
        rule.loader ||
        (Array.isArray(rule.use)
          ? rule.use[0] && (rule.use[0].loader || rule.use[0])
          : rule.use && (rule.use.loader || rule.use));
      if (typeof loader !== 'string') return false;
      return useEntryIsVueLoader(loader) || loader.startsWith(VUE_LOADER_INDEX);
    });

    // eslint-disable-next-line no-param-reassign -- the plugin rewrites the compiler's rule list
    compiler.options.module.rules = [
      pitcher,
      ...rules.filter((rule) => !vueLoaderRules.includes(rule)),
      ...(VUE_LOADER.needsTemplateRule(compiler.options.context) ? [templateCompilerRule] : []),
      ...vueLoaderRules,
    ];
  }
}

VueLoaderPlugin.NS = NS;
module.exports = VueLoaderPlugin;
module.exports.VueLoaderPlugin = VueLoaderPlugin;
