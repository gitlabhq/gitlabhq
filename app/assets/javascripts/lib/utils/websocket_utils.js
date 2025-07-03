/**
 * Manages a Websocket Connection
 * @param {string} url - WebSocket URL
 * @param {Object} options - Configuration options
 * @param {Function} options.onOpen - Open handler
 * @param {Function} options.onMessage - Message handler
 * @param {Function} options.onError - Error handler
 * @param {Function} options.onClose - Close handler
 * @returns {Object} WebSocket connection object with utility methods
 */
export const createWebSocket = (url, options = {}) => {
  const {
    onOpen = () => {},
    onMessage = () => {},
    onError = () => {},
    onClose = () => {},
  } = options;

  let socket = null;

  const close = () => {
    if (socket?.readyState === WebSocket.OPEN || socket?.readyState === WebSocket.CONNECTING) {
      socket.close();
    }
    socket = null;
  };

  const isConnected = () => {
    return socket?.readyState === WebSocket.OPEN;
  };

  const send = (message) => {
    if (isConnected()) {
      const payload = typeof message === 'string' ? message : JSON.stringify(message);
      socket.send(payload);
    }
  };

  const connect = (initialMessage = null) => {
    close(); // Close any existing connection

    try {
      socket = new WebSocket(url);

      socket.onopen = (event) => {
        if (initialMessage) {
          send(initialMessage);
        }

        onOpen(event);
      };

      socket.onmessage = (event) => {
        onMessage(event);
      };

      socket.onclose = (event) => {
        socket = null;
        onClose(event);
      };

      socket.onerror = (error) => {
        onError(error);
      };
    } catch (error) {
      onError(error);
    }
  };

  const isConnecting = () => {
    return socket?.readyState === WebSocket.CONNECTING;
  };

  return {
    connect,
    send,
    isConnected,
    isConnecting,
    close,
  };
};

/**
 * Parses JSON message from WebSocket event
 * @param {MessageEvent} event - The WebSocket message event
 * @returns {Promise<Object|null>} Parsed message data or null if parsing fails
 */
export const parseMessage = async (event) => {
  try {
    const data = typeof event.data === 'string' ? event.data : await event.data.text();
    return JSON.parse(data);
  } catch (error) {
    return null;
  }
};

/**
 * Safe socket cleanup utility
 * @param {Object|WebSocket} socket - The socket to close
 */
export const closeSocket = (socket) => {
  if (typeof socket?.close === 'function') {
    socket.close();
  }
};
