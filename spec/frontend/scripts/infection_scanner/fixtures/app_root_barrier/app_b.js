import Vue from 'vue';
import { shared } from './shared';
import { infected } from './infected_lib';

shared();
infected();

// eslint-disable-next-line no-new
new Vue({ el: '#b', name: 'AppB' });
