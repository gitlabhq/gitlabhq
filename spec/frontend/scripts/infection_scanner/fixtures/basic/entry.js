import Vue from 'vue';
import { initApp } from './app';

Vue.use({});
initApp();

// eslint-disable-next-line no-new
new Vue({ el: '#app', name: 'AppEntry' });
