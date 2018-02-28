import axios from 'axios';
import csrf from './csrf';

axios.defaults.headers.common[csrf.headerKey] = csrf.token;

// Maintain a global counter for active requests
// see: spec/support/wait_for_requests.rb
axios.interceptors.request.use((config) => {
  window.activeVueResources = window.activeVueResources || 0;
  window.activeVueResources += 1;

  return config;
});

// Remove the global counter
axios.interceptors.response.use((config) => {
  window.activeVueResources -= 1;

  return config;
});

export default axios;
