require('vendor/xterm/encoding-indexes.js');
require('vendor/xterm/encoding.js');
window.Terminal = require('vendor/xterm/xterm.js');
require('vendor/xterm/fit.js');
require('./terminal.js');

$(() => new gl.Terminal({ selector: '#terminal' }));
