import Vue from 'vue';
import IntervalPatternInput from './components/interval_pattern_input';
import TimezoneDropdown from './components/timezone_dropdown';

document.addEventListener('DOMContentLoaded', () => {
  new TimezoneDropdown();

  const IntervalPatternInputComponent = Vue.extend(IntervalPatternInput);

  new IntervalPatternInputComponent({
    propsData: {
      initialCronInterval: '0 0 0 0 0',
    },
  }).$mount('#interval-pattern-input');

  new gl.GlFieldErrors(document.querySelector('#new-pipeline-schedule-form'));
});
