import Vue from 'vue';
import IntervalPatternInput from './components/interval_pattern_input';
import TimezoneDropdown from './components/timezone_dropdown';
import TargetBranchDropdown from './components/target_branch_dropdown';

document.addEventListener('DOMContentLoaded', () => {
  const IntervalPatternInputComponent = Vue.extend(IntervalPatternInput);
  const intervalPatternMount = document.getElementById('interval-pattern-input');

  new IntervalPatternInputComponent({
    propsData: {
      initialCronInterval: intervalPatternMount.dataset.initialInterval,
    },
  }).$mount(intervalPatternMount);

  const formElement = document.querySelector('#new-pipeline-schedule-form');

  gl.timezoneDropdown = new TimezoneDropdown();
  gl.targetBranchDropdown = new TargetBranchDropdown();
  gl.pipelineScheduleFieldErrors = new gl.GlFieldErrors(formElement);
});
