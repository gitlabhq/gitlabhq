<script>
  export default {
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
       <i>{{note.body}}</i>
     </div>
   </div>
  </li>
</template>
