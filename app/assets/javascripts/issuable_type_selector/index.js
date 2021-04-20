import Vue from 'vue';
import InfoPopover from './components/info_popover.vue';

export default function initIssuableTypeSelector() {
  const el = document.getElementById('js-type-popover');

  return new Vue({
    el,
    components: {
      InfoPopover,
    },
    render(h) {
      return h(InfoPopover);
    },
  });
}
