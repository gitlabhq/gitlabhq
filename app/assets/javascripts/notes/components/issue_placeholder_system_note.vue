<script>
  export default {
    name: 'placeholderSystemNote',
    props: {
      note: {
        type: Object,
        required: true,
      },
    },
  };
</script>

<template>
  <li class="note system-note timeline-entry being-posted fade-in-half">
   <div class="timeline-entry-inner">
     <div class="timeline-content">
       <em>{{note.body}}</em>
     </div>
   </div>
  </li>
</template>
