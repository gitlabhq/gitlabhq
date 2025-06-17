import Vue from 'vue';

export const hashState = Vue.observable({
  currentHash: window.location.hash,
});

export const updateHash = (newHash) => {
  hashState.currentHash = newHash;
};
