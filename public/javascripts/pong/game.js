import Score from './score';
import Ball from './ball';
import User from './user';
import Computer from './computer';

class Game {
  constructor(container, ball, score, userPaddle, computerPaddle) {
    this.container = container;

    this.score = new Score(score);
    this.ball = new Ball(ball);
    this.user = new User(userPaddle);
    this.computer = new Computer(computerPaddle);
  }

  init() {
    this.setContainer();

    // Temporary, should `start` when an space or arrow key is pressed.
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

export default Game;
