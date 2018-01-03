import Vue from 'vue';

const eventHub = new Vue();

// TODO: remove eventHub hack after code splitting refactor
window.emitSidebarEvent = (...args) => eventHub.$emit(...args);

export default eventHub;
