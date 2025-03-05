import Vue from 'vue';

export const lineState = Vue.observable({
  currentLineNumber: null,
});

export const updateLineNumber = (lineNumber) => {
  lineState.currentLineNumber = lineNumber;
};
