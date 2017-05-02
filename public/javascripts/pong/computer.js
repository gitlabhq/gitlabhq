import Paddle from './paddle';

class Computer {
  constructor(paddle) {
    this.paddle = new Paddle(paddle, 'top');
  }
}

export default Computer;
