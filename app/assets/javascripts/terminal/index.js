import 'vendor/xterm/encoding-indexes';
import 'vendor/xterm/encoding';
import Terminal from 'xterm';
import './terminal';

window.Terminal = Terminal;

export default () => new gl.Terminal({ selector: '#terminal' });
