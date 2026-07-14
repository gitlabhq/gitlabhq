const { autoEntriesCount } = require('./entries');

const universal = Math.ceil(autoEntriesCount * 0.9);

const cacheGroups = {
  default: false,
  gitlab_ui: {
    priority: 26,
    name: 'gitlab_ui',
    chunks: 'all',
    test: /[\\/]node_modules[\\/]@gitlab[\\/]ui[\\/]/,
    minChunks: universal,
  },
  framework: {
    priority: 25,
    name: 'framework',
    chunks: 'all',
    test: /[\\/]node_modules[\\/]/,
    minChunks: universal,
  },
  common: {
    priority: 20,
    name: 'main',
    chunks: 'all',
    minChunks: universal,
  },
  prosemirror: {
    priority: 17,
    name: 'prosemirror',
    chunks: 'all',
    test: /[\\/]node_modules[\\/]prosemirror.*?[\\/]/,
    minChunks: 2,
    reuseExistingChunk: true,
  },
  monaco: {
    priority: 15,
    name: 'monaco',
    chunks: 'all',
    test: /[\\/]node_modules[\\/]monaco-editor[\\/]/,
    minChunks: 2,
    reuseExistingChunk: true,
  },
  echarts: {
    priority: 14,
    name: 'echarts',
    chunks: 'all',
    test: /[\\/]node_modules[\\/](echarts|zrender)[\\/]/,
    minChunks: 2,
    reuseExistingChunk: true,
  },
  vendors: {
    priority: 10,
    chunks: 'async',
    test: /[\\/](node_modules|vendor[\\/]assets[\\/]javascripts)[\\/]/,
  },
  commons: {
    chunks: 'all',
    minChunks: 2,
    reuseExistingChunk: true,
  },
};

module.exports = { cacheGroups };
