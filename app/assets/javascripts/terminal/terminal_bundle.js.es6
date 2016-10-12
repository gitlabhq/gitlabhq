//= require ./xterm/xterm.js
//= require ./xterm/attach.js
//= require ./xterm/fit.js
//= require ./terminal.js

$(() => {
  new gl.Terminal({
    selector: '#terminal'
  });
});
