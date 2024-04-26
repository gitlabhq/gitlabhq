import RubyPlugin from 'vite-plugin-ruby';

const [rubyPlugin, ...rest] = RubyPlugin.default();

/**
 * A fixed version of vite-plugin-ruby
 *
 * We can't use regular 'resolve' which points to sourceCodeDir in vite.json
 * Because we need for '~' alias to resolve to app/assets/javascripts
 * We can't use javascripts folder in sourceCodeDir because we also need to resolve other assets
 * With undefined 'resolve' an '~' alias from Webpack config is used instead
 * See the issue for details: https://github.com/ElMassimo/vite_ruby/issues/237
 */
export function FixedRubyPlugin() {

  return [
    {
      ...rubyPlugin,
      name: 'vite-plugin-ruby-fixed',
      config: (...args) => {
        const originalConfig = rubyPlugin.config(...args);
        return {
          ...originalConfig,
          resolve: undefined,
        };
      },
    },
    ...rest,
  ];
}
