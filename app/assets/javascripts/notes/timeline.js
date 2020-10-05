import Vue from 'vue';
import TimelineToggle from './components/timeline_toggle.vue';

export default function initTimelineToggle(store) {
  const el = document.getElementById('js-incidents-timeline-toggle');

  if (!el) return null;

  return new Vue({
    el,
    store,
    render(createElement) {
      return createElement(TimelineToggle);
    },
  });
}
