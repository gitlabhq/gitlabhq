import Keyboard from './keyboard';
import Paddle from './paddle';

class User {
  constructor(paddle) {
    this.paddle = new Paddle(paddle, 'bottom');
    this.keyboard = new Keyboard();
  }
}

export default User;
