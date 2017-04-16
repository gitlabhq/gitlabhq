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

class User {
  constructor(paddle) {
    this.paddle = new Paddle(paddle, 'bottom');
    this.keyboard = new Keyboard();
  }
}

class Computer {
  constructor(paddle) {
    this.paddle = new Paddle(paddle, 'top');
  }
}

class Paddle {
  constructor(element) {
    this.element;
  }
}

class Ball {
  contructor(element) {
    this.element = element;
  }

  start() {
    return true;
  }
}

class Score {
  constructor(element) {
    this.element = element;
    this.points = parseInt(element.innerText);
  }

  start() {
    this.points = Math.floor(this.points * 0.925);

    this.element.innerText = this.points;

    return this.points === 0;
  }
}

class Pong {
  constructor(container, ball, score, userPaddle, computerPaddle) {
    this.container = container;

    this.score = new Score(score);
    this.ball = new Ball(ball);
    this.user = new User(userPaddle);
    this.computer = new Computer(computerPaddle);
  }

  init() {
    this.setContainer();

    setTimeout(this.start.bind(this, this.play.bind(this)), 250);
  }

  start(done) {
    let returnValues = [];

    returnValues.push(
      this.score.start(),
      this.ball.start()
      // this.user.start(),
      // this.computer.start(),
    );

    if (returnValues.indexOf(false) === -1) return done();

    window.requestAnimationFrame(this.start.bind(this, done));
  }

  play(done) {
    // this.score.nextFrame.call(this.score);
    // this.user.nextFrame.call(this.user);
    // this.computer.nextFrame.call(this.computer);
    // this.ball.nextFrame.call(this.ball);

    window.requestAnimationFrame(this.play.bind(this));
  }

  setContainer() {
    this.container.classList.add('game-active');
  }
}

const logo = document.getElementById('logo');
const errorCode = document.getElementById('error-code');
const container = document.getElementById('container');
const userPaddle = document.getElementById('user');
const computerPaddle = document.getElementById('computer');

const pong = new Pong(
  container,
  logo,
  errorCode,
  userPaddle,
  computerPaddle
);

setTimeout(() => {
  pong.init();
}, 2000);
