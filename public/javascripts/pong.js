// const KEY_SYMBOLS = {
//   SPACE: Symbol('SPACE'),
//   LEFT: Symbol('LEFT'),
//   RIGHT: Symbol('RIGHT'),
// };
//
// const KEY_MAP = new Map([
//   [32, KEY_SYMBOLS.SPACE],
//   [37, KEY_SYMBOLS.LEFT],
//   [39, KEY_SYMBOLS.RIGHT],
// ]);
//
// class Keyboard {
//   init() {
//     document.addEventListener('keydown', this.readInput.bind(this));
//   }
//
//   readInput(event) {
//     const keyCode = event.which || event.keyCode;
//
//     switch (KEY_MAP.get(keyCode)) {
//       case KEY_SYMBOLS.SPACE:
//
//         break;
//       default:
//
//     }
//   }
// }

// class User {
//   constructor() {
//     this.paddle = new Paddle();
//     this.keyboard = new Keyboard();
//   }
// }

// class Computer {
//   constructor() {
//     this.paddle = new Paddle();
//   }
// }

// class Paddle {
//   constructor() {
//
//   }
// }

class Ball {
  contructor(element) {
    this.element = element;
  }

  start() {
    return
  }
}

class Score {
  constructor(element) {
    this.element = element;
    this.points = parseInt(element.innerText);
  }

  start() {
    this.points = Math.floor(this.points * 0.9);

    this.element.innerText = this.points;

    return this.points === 0;
  }
}

class Pong {
  constructor(containerElement, ballElement, scoreElement) {
    this.container = containerElement;

    this.setContainer();

    this.score = new Score(scoreElement);
    this.ball = new Ball(ballElement);
    // this.user = new User();
    // this.computer = new Computer();
  }

  init() {
    this.start(this.play.bind(this));
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

  }
}

const logo = document.getElementById('logo');
const errorCode = document.getElementById('error-code');
const container = document.getElementById('container');

const pong = new Pong(container, logo, errorCode);

setTimeout(() => {
  pong.init();
}, 2000);
