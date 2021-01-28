const div = document.createElement('div');

Object.assign(div.style, {
  width: '100vw',
  height: '100vh',
  position: 'fixed',
  top: 0,
  left: 0,
  'z-index': 100000,
  background: 'rgba(0,0,0,0.9)',
  'font-size': '25px',
  'font-family': 'monospace',
  color: 'white',
  padding: '2.5em',
  'text-align': 'center',
});

div.innerHTML = `
<h1 style="color:white">🧙 Webpack is doing its magic 🧙</h1>
<p>If you use Hot Module reloading, the page will reload in a few seconds.</p>
<p>If you do not use Hot Module reloading, please <a href="">reload the page manually in a few seconds</a></p>
`;

document.body.append(div);
