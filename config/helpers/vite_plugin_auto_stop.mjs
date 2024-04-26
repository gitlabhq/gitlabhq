import chokidar from 'chokidar';

/**
 * This vite plugin automatically stops vite if
 *
 * 1. a new dependency install happened, because it could affect vite itself
 * 2. a new entry point is created, because right now our entry points are
 *    statically looked at during start up
 */
export function AutoStopPlugin() {
  return {
    name: 'vite-plugin-auto-stop',
    configureServer(server) {
      const nodeModulesWatcher = chokidar.watch(['node_modules/.yarn-integrity'], {
        ignoreInitial: true,
      });
      const pageEntrypointsWatcher = chokidar.watch(
        [
          'app/assets/javascripts/pages/**/*.js',
          'ee/app/assets/javascripts/pages/**/*.js',
          'jh/app/assets/javascripts/pages/**/*.js',
        ],
        {
          ignoreInitial: true,
        },
      );

      // GDK will restart Vite server for us
      const stop = () => process.kill(process.pid);

      pageEntrypointsWatcher.on('add', stop);
      pageEntrypointsWatcher.on('unlink', stop);
      nodeModulesWatcher.on('add', stop);
      nodeModulesWatcher.on('change', stop);
      nodeModulesWatcher.on('unlink', stop);

      server.httpServer?.addListener?.('close', () => {
        pageEntrypointsWatcher.close();
        nodeModulesWatcher.close();
      });
    },
  };
}
