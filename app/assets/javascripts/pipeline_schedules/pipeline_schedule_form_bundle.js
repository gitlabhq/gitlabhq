import Vue from 'vue';
import IntervalPatternInput from './components/interval_pattern_input';
import TimezoneDropdown from './components/timezone_dropdown';
import TargetBranchDropdown from './components/target_branch_dropdown';

document.addEventListener('DOMContentLoaded', () => {
  gl.timezoneDropdown = new TimezoneDropdown();
  gl.targetBranchDropdown = new TargetBranchDropdown();

  const IntervalPatternInputComponent = Vue.extend(IntervalPatternInput);
  const intervalPatternMount = document.getElementById('interval-pattern-input');

  new IntervalPatternInputComponent({
    propsData: {
      initialCronInterval: intervalPatternMount.dataset.initialInterval,
    },
  }).$mount(intervalPatternMount);

  gl.pipelineScheduleFieldErrors = new gl.GlFieldErrors(document.querySelector('#new-pipeline-schedule-form'));
});
