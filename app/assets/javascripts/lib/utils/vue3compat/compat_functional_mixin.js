import Vue from 'vue';

export const compatFunctionalMixin = Vue.version.startsWith('3')
  ? {
      created() {
        this.props = this.$props;
        this.listeners = this.$listeners;
      },
    }
  : {
      created() {
        throw new Error('This mixin should not be executed in Vue.js 2');
      },
    };
