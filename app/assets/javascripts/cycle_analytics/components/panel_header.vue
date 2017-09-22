<script>
  export default {
    props: {
      currentStage: {
        type: Object,
        required: true,
      },
    },
  };
</script>
<template>
  <div class="panel-heading">
    <div class="nav col-headers">
      <ul>
        <li class="stage-header">
          <span class="stage-name">
            {{s__('ProjectLifecycle|Stage')}}
          </span>
          <i
            class="fa fa-question-circle"
            v-tooltip
            :title="_("The phase of the development lifecycle.")"
            data-placement="top"
            aria-hidden="true">
          </i>
        </li>
        <li class="median-header">
          <span class="stage-name">
            {{ __('Median') }}
          </span>
          <i
            class="fa fa-question-circle"
            v-tooltip
            :title="_("The value lying at the midpoint of a series of observed values. E.g., between 3, 5, 9, the median is 5. Between 3, 5, 7, 8, the median is (5+7)/2 = 6.")"
            data-placement="top"
            aria-hidden="true">
          </i>
        </li>
        <li class="event-header">
          <span class="stage-name">
            {{ currentStage ? __(currentStage.legend) : __('Related Issues') }}
          </span>
          <i
            class="fa fa-question-circle"
            v-tooltip
            :title="_("The collection of events added to the data gathered for that stage.")"
            data-placement="top"
            aria-hidden="true">
          </i>
        </li>
        <li class="total-time-header">
          <span class="stage-name">
            {{ __('Total Time') }}
          </span>
          <i
            class="fa fa-question-circle"
            v-tooltip
            :title="_("The time taken by each data entry gathered by that stage.")"
            data-placement="top"
            aria-hidden="true">
          </i>
        </li>
      </ul>
    </div>
  </div>
</template>
