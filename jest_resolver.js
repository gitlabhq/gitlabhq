const fs = require('fs');

// Wrap jest default resolver to detect missing frontend fixtures.
module.exports = (request, options) => {
  try {
    return options.defaultResolver(request, options);
  } catch (e) {
    if (request.match(/tmp\/tests\/frontend\/fixtures/) && !fs.existsSync(request)) {
      console.error(
        '\x1b[1m\x1b[41m\x1b[30m %s \x1b[0m %s',
        '!',
        `Fixture file ${request} does not exist. Did you run bin/rake frontend:fixtures? You can also download fixtures from the gitlab-org/gitlab package registry. See the Fixtures docs for more info.`,
      );
    }
    throw e;
  }
};
