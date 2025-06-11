<script>
import ActivityWidget from './activity_widget.vue';
import TodosWidget from './todos_widget.vue';

export default {
  components: { ActivityWidget, TodosWidget },
};
</script>

<template>
  <div>
    <h1>{{ __("Today's highlights") }}</h1>
    <todos-widget />
    <activity-widget />
  </div>
</template>
