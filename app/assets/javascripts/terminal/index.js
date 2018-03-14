import 'vendor/xterm/encoding-indexes';
import 'vendor/xterm/encoding';
import Terminal from 'vendor/xterm/xterm';
import 'vendor/xterm/fit';
import './terminal';

window.Terminal = Terminal;

export default () => new gl.Terminal({ selector: '#terminal' });
