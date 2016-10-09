(() => {
  const global = window.gl || (window.gl = {});

  class LoadScript {
    static load(source, id = '') {
      if (!source) return Promise.reject('source url must be defined');
      if (id && document.querySelector(`#${id}`)) return Promise.reject('script id already exists');
      return new Promise((resolve, reject) => this.appendScript(source, id, resolve, reject));
    }

    static appendScript(source, id, resolve, reject) {
      const scriptElement = document.createElement('script');
      scriptElement.type = 'text/javascript';
      if (id) scriptElement.id = id;
      scriptElement.onload = resolve;
      scriptElement.onerror = reject;
      scriptElement.src = source;

      document.body.appendChild(scriptElement);
    }
  }

  global.LoadScript = LoadScript;

  return global.LoadScript;
})();
