import 'vendor/xterm/encoding-indexes';
import 'vendor/xterm/encoding';
import Terminal from 'xterm/xterm';
import 'xterm/fit/fit';
import './terminal';

window.Terminal = Terminal;

export default () => new gl.Terminal({ selector: '#terminal' });
