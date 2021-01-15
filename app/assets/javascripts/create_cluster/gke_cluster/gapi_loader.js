// This is a helper module to lazily import the google APIs for the GKE cluster
// integration without introducing an indirect global dependency on an
// initialized window.gapi object.
export default () => {
  if (window.gapiPromise === undefined) {
    // first time loading the module
    window.gapiPromise = new Promise((resolve, reject) => {
      // this callback is set as a query param to script.src URL
      window.onGapiLoad = () => {
        resolve(window.gapi);
      };

      const script = document.createElement('script');
      // do not use script.onload, because gapi continues to load after the initial script load
      script.type = 'text/javascript';
      script.async = true;
      script.src = 'https://apis.google.com/js/api.js?onload=onGapiLoad';
      script.onerror = reject;
      document.head.appendChild(script);
    });
  }

  return window.gapiPromise;
};
