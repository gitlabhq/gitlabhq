import Vue from 'vue';
import base from '~/boards/components/modal/index.vue';
import ModalFooter from './footer';

gl.issueBoards.IssuesModal = Vue.extend(base, {
  components: {
    ModalFooter,
  },
});
