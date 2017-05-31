import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

// Inject Private Token + Target URL
Vue.http.interceptors.push((request, next) => {
  if (request.url.indexOf('[[API]]') > -1) {
    const privateToken = gl.utils.getParameterByName('privateToken') || 'u8awsaDqQr-TDbrf8Kxq';
    const baseUrl = window.gl.target === 'local' ? '/api/v4' : 'https://gitlab.com/api/v4';

    // eslint-disable-next-line no-param-reassign
    request.url = request.url.replace('[[API]]', baseUrl);

    // eslint-disable-next-line no-param-reassign
    request.headers['PRIVATE-TOKEN'] = privateToken;
  }
  
  next();
});
