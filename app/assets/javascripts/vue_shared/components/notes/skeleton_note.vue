<template>
  <li class="timeline-entry note">
    <div class="timeline-entry-inner">
      <div class="timeline-icon">
      </div>
      <div class="timeline-content">
        <div class="note-header"></div>
        <div class="note-body">
          <skeleton-loading-container />
        </div>
      </div>
    </div>
  </li>
</template>

<script>
  import skeletonLoadingContainer from '~/vue_shared/components/skeleton_loading_container.vue';

  export default {
    components: {
      skeletonLoadingContainer,
    },
  };
</script>
