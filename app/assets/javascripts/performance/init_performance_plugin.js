import Vue from 'vue';
import PerformancePlugin from './vue_performance_plugin';

export default function initPerformancePlugin(components) {
  Vue.use(PerformancePlugin, { components });
}
