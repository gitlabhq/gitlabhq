import { createWebSocket, parseMessage, closeSocket } from '~/lib/utils/websocket_utils';

const TEST_URL = 'ws://test.com';
const INVALID_INPUTS = [
  ['null', null],
  ['undefined', undefined],
  ['object without required method', { someOtherMethod: jest.fn() }],
];
global.WebSocket = jest.fn();

global.WebSocket.CONNECTING = 0;
global.WebSocket.OPEN = 1;
global.WebSocket.CLOSING = 2;
global.WebSocket.CLOSED = 3;

const createAndConnectSocket = (url = TEST_URL, handlers = {}) => {
  const connection = createWebSocket(url, handlers);
  connection.connect();
  return connection;
};

describe('WebSocket Utils', () => {
  let mockWebSocket;

  beforeEach(() => {
    jest.clearAllMocks();

    mockWebSocket = {
      readyState: global.WebSocket.CONNECTING,
      send: jest.fn(),
      close: jest.fn(),
      onopen: null,
      onmessage: null,
      onclose: null,
      onerror: null,
    };

    global.WebSocket.mockImplementation(() => mockWebSocket);
  });

  describe('createWebSocket', () => {
    describe('initialization', () => {
      it('should create connection object with default handlers', () => {
        const connection = createWebSocket(TEST_URL);

        expect(connection).toHaveProperty('connect');
        expect(connection).toHaveProperty('send');
        expect(connection).toHaveProperty('isConnected');
        expect(connection).toHaveProperty('isConnecting');
        expect(connection).toHaveProperty('close');

        expect(typeof connection.connect).toBe('function');
        expect(typeof connection.send).toBe('function');
        expect(typeof connection.isConnected).toBe('function');
        expect(typeof connection.isConnecting).toBe('function');
        expect(typeof connection.close).toBe('function');
      });

      it('should create WebSocket instance when connect is called', () => {
        createAndConnectSocket();

        expect(global.WebSocket).toHaveBeenCalledWith(TEST_URL);
        expect(global.WebSocket).toHaveBeenCalledTimes(1);
      });
    });

    describe('event handlers', () => {
      it('should call custom event handlers when WebSocket events occur', () => {
        const mockOnOpen = jest.fn();
        const mockOnMessage = jest.fn();
        createAndConnectSocket(TEST_URL, {
          onOpen: mockOnOpen,
          onMessage: mockOnMessage,
        });

        mockWebSocket.onopen({ type: 'open' });
        expect(mockOnOpen).toHaveBeenCalledTimes(1);
        expect(mockOnOpen).toHaveBeenCalledWith({ type: 'open' });

        const messageEvent = { type: 'message', data: 'test message' };
        mockWebSocket.onmessage(messageEvent);
        expect(mockOnMessage).toHaveBeenCalledTimes(1);
        expect(mockOnMessage).toHaveBeenCalledWith(messageEvent);
      });

      it('should call onError and onClose handlers', () => {
        const mockOnError = jest.fn();
        const mockOnClose = jest.fn();
        createAndConnectSocket(TEST_URL, {
          onError: mockOnError,
          onClose: mockOnClose,
        });

        const errorEvent = { type: 'error', message: 'Connection failed' };
        mockWebSocket.onerror(errorEvent);
        expect(mockOnError).toHaveBeenCalledTimes(1);
        expect(mockOnError).toHaveBeenCalledWith(errorEvent);

        const closeEvent = { type: 'close', code: 1000 };
        mockWebSocket.onclose(closeEvent);
        expect(mockOnClose).toHaveBeenCalledTimes(1);
        expect(mockOnClose).toHaveBeenCalledWith(closeEvent);
      });

      it('should call onError handler when WebSocket constructor throws', () => {
        const mockOnError = jest.fn();

        const constructorError = new Error('WebSocket constructor failed');
        global.WebSocket.mockImplementation(() => {
          throw constructorError;
        });
        createAndConnectSocket(TEST_URL, { onError: mockOnError });

        expect(mockOnError).toHaveBeenCalledTimes(1);
        expect(mockOnError).toHaveBeenCalledWith(constructorError);
      });
    });

    describe('connection state', () => {
      describe('isConnected', () => {
        it.each([
          [global.WebSocket.CONNECTING, false],
          [global.WebSocket.OPEN, true],
          [global.WebSocket.CLOSING, false],
          [global.WebSocket.CLOSED, false],
        ])('should return %s when readyState is %s', (readyState, expected) => {
          const connection = createAndConnectSocket();

          mockWebSocket.readyState = readyState;
          expect(connection.isConnected()).toBe(expected);
        });
      });

      describe('isConnecting', () => {
        it.each([
          [global.WebSocket.CONNECTING, true],
          [global.WebSocket.OPEN, false],
          [global.WebSocket.CLOSING, false],
          [global.WebSocket.CLOSED, false],
        ])('should return %s when readyState is %s', (readyState, expected) => {
          const connection = createAndConnectSocket();

          mockWebSocket.readyState = readyState;
          expect(connection.isConnecting()).toBe(expected);
        });
      });
    });

    describe('send', () => {
      it('should send string message when connected', () => {
        const connection = createAndConnectSocket();

        mockWebSocket.readyState = global.WebSocket.OPEN;

        connection.send('test message');

        expect(mockWebSocket.send).toHaveBeenCalledTimes(1);
        expect(mockWebSocket.send).toHaveBeenCalledWith('test message');
      });

      it('should stringify object message when connected', () => {
        const connection = createAndConnectSocket();

        mockWebSocket.readyState = global.WebSocket.OPEN;

        const message = { type: 'test', data: 'value' };
        connection.send(message);

        expect(mockWebSocket.send).toHaveBeenCalledTimes(1);
        expect(mockWebSocket.send).toHaveBeenCalledWith(JSON.stringify(message));
      });

      it('should not send message when not connected', () => {
        const connection = createAndConnectSocket();

        mockWebSocket.readyState = global.WebSocket.CONNECTING;

        connection.send('test message');

        expect(mockWebSocket.send).not.toHaveBeenCalled();
      });
    });
    describe('close', () => {
      it('should close socket when in OPEN state', () => {
        const connection = createAndConnectSocket();

        mockWebSocket.readyState = global.WebSocket.OPEN;
        connection.close();

        expect(mockWebSocket.close).toHaveBeenCalledTimes(1);
      });

      it('should close socket when in CONNECTING state', () => {
        const connection = createAndConnectSocket();

        mockWebSocket.readyState = global.WebSocket.CONNECTING;
        connection.close();

        expect(mockWebSocket.close).toHaveBeenCalledTimes(1);
      });

      it('should not close socket when in CLOSED state', () => {
        const connection = createAndConnectSocket();

        mockWebSocket.readyState = global.WebSocket.CLOSED;
        connection.close();

        expect(mockWebSocket.close).not.toHaveBeenCalled();
      });
    });

    describe('parseMessage', () => {
      it('should parse JSON string message', async () => {
        const event = { data: '{"type": "test", "value": 123}' };
        const result = await parseMessage(event);

        expect(result).toEqual({ type: 'test', value: 123 });
      });

      it('should return null for invalid JSON', async () => {
        const event = { data: 'invalid json' };
        const result = await parseMessage(event);

        expect(result).toBeNull();
      });

      it('should handle empty string', async () => {
        const event = { data: '' };
        const result = await parseMessage(event);

        expect(result).toBeNull();
      });
    });
  });

  describe('closeSocket', () => {
    it('should call close method when socket has close method', () => {
      const mockSocket = {
        close: jest.fn(),
      };

      closeSocket(mockSocket);

      expect(mockSocket.close).toHaveBeenCalledTimes(1);
    });

    it.each(INVALID_INPUTS)('should not throw when socket is %s', (description, socket) => {
      expect(() => closeSocket(socket)).not.toThrow();
    });
  });
});
