import Vue from 'vue';
import IntervalPatternInput from './components/interval_pattern_input';
import TimezoneDropdown from './components/timezone_dropdown';
import TargetBranchDropdown from './components/target_branch_dropdown';

document.addEventListener('DOMContentLoaded', () => {
  const IntervalPatternInputComponent = Vue.extend(IntervalPatternInput);
  const intervalPatternMount = document.getElementById('interval-pattern-input');
  const initialCronInterval = intervalPatternMount ? intervalPatternMount.dataset.initialInterval : '';

  new IntervalPatternInputComponent({
    propsData: {
      initialCronInterval,
    },
  }).$mount(intervalPatternMount);

  const formElement = document.getElementById('new-pipeline-schedule-form');
  gl.timezoneDropdown = new TimezoneDropdown();
  gl.targetBranchDropdown = new TargetBranchDropdown();
  gl.pipelineScheduleFieldErrors = new gl.GlFieldErrors(formElement);
});
