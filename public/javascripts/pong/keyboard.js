const KEY_SYMBOLS = {
  SPACE: Symbol('SPACE'),
  LEFT: Symbol('LEFT'),
  RIGHT: Symbol('RIGHT'),
};

const KEY_MAP = new Map([
  [32, KEY_SYMBOLS.SPACE],
  [37, KEY_SYMBOLS.LEFT],
  [39, KEY_SYMBOLS.RIGHT],
]);

class Keyboard {
  init() {
    document.addEventListener('keydown', this.readInput.bind(this));
  }

  readInput(event) {
    const keyCode = event.which || event.keyCode;

    switch (KEY_MAP.get(keyCode)) {
      case KEY_SYMBOLS.SPACE:
        break;
      case KEY_SYMBOLS.LEFT:
      case KEY_SYMBOLS.RIGHT:
        break;
    }
  }
}

export {
  KEY_SYMBOLS,
  KEY_MAP,
  Keyboard as default,
};
