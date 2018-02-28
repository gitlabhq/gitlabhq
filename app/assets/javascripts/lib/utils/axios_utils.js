import axios from 'axios';
import csrf from './csrf';

export default function setAxiosCsrfToken() {
  axios.defaults.headers.common[csrf.headerKey] = csrf.token;
}
