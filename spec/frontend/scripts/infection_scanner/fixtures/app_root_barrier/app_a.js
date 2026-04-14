import Vue from 'vue';
import { shared } from './shared';

shared();

// eslint-disable-next-line no-new
new Vue({ el: '#a', name: 'AppA' });
