//= require ./xterm/xterm.js
//= require ./xterm/attach.js
//= require ./xterm/fit.js
//= require ./terminal.js

$(function() {
  new gl.Terminal({
    selector: '#terminal'
  });
});
