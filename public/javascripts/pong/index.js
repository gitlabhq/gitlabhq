import Game from './game';

const logo = document.getElementById('logo');
const errorCode = document.getElementById('error-code');
const container = document.getElementById('container');
const userPaddle = document.getElementById('user');
const computerPaddle = document.getElementById('computer');

const game = new Game(
  container,
  logo,
  errorCode,
  userPaddle,
  computerPaddle
);

game.init();
