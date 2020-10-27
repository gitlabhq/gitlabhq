import Vue from 'vue';
import { mapGetters } from 'vuex';
import IssuableApp from './components/app.vue';

export default function initIssuableApp(issuableData, store) {
  return new Vue({
    el: document.getElementById('js-issuable-app'),
    store,
    computed: {
      ...mapGetters(['getNoteableData']),
    },
    render(createElement) {
      return createElement(IssuableApp, {
        props: {
          ...issuableData,
          issuableStatus: this.getNoteableData?.state,
        },
      });
    },
  });
}
