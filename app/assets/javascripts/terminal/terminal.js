import { Terminal } from 'xterm';
import * as fit from 'xterm/lib/addons/fit/fit';
import * as webLinks from 'xterm/lib/addons/webLinks/webLinks';
import { __ } from '~/locale';

Terminal.applyAddon(fit);
Terminal.applyAddon(webLinks);

export default class GLTerminal {
  constructor(element, options = {}) {
    this.options = {
      cursorBlink: true,
      screenKeys: true,
      ...options,
    };

    this.container = element;
    this.onDispose = [];

    this.setSocketUrl();
    this.createTerminal();

    const resizeObserver = new ResizeObserver(() => this.terminal.fit());
    resizeObserver.observe(this.container);
    this.onDispose.push(() => resizeObserver.disconnect());
  }

  setSocketUrl() {
    const { protocol, hostname, port } = window.location;
    const wsProtocol = protocol === 'https:' ? 'wss://' : 'ws://';
    const path = this.container.dataset.projectPath;

    this.socketUrl = `${wsProtocol}${hostname}:${port}${path}`;
  }

  createTerminal() {
    this.terminal = new Terminal(this.options);

    this.socket = new WebSocket(this.socketUrl, ['terminal.gitlab.com']);
    this.socket.binaryType = 'arraybuffer';

    this.terminal.open(this.container);
    this.terminal.fit();
    this.terminal.webLinksInit();
    this.terminal.focus();

    this.socket.onopen = () => {
      this.runTerminal();
    };
    this.socket.onerror = () => {
      this.handleSocketFailure();
    };
  }

  runTerminal() {
    const decoder = new TextDecoder('utf-8');
    const encoder = new TextEncoder('utf-8');

    this.terminal.on('data', (data) => {
      this.socket.send(encoder.encode(data));
    });

    this.socket.addEventListener('message', (ev) => {
      this.terminal.write(decoder.decode(ev.data));
    });

    this.isTerminalInitialized = true;
    this.terminal.fit();
  }

  handleSocketFailure() {
    this.terminal.write('\r\n');
    this.terminal.write(__('Connection failure'));
  }

  disable() {
    this.terminal.setOption('cursorBlink', false);
    this.terminal.setOption('theme', { foreground: '#707070' });
    this.terminal.setOption('disableStdin', true);
    this.socket.close();
  }

  dispose() {
    // eslint-disable-next-line @gitlab/no-global-event-off
    this.terminal.off('data');
    this.terminal.dispose();
    this.socket.close();

    this.onDispose.forEach((fn) => fn());
    this.onDispose.length = 0;
  }

  scrollToTop() {
    this.terminal.scrollToTop();
  }

  scrollToBottom() {
    this.terminal.scrollToBottom();
  }

  fit() {
    this.terminal.fit();
  }
}
