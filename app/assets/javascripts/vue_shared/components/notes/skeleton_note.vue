<script>
import SkeletonLoading from '@gitlab-org/gitlab-ui/dist/components/base/skeleton_loading';

export default {
  name: 'SkeletonNote',
  components: {
    SkeletonLoading,
  },
};
</script>

<template>
  <li class="timeline-entry note">
    <div class="timeline-entry-inner">
      <div class="timeline-icon">
      </div>
      <div class="timeline-content">
        <div class="note-header"></div>
        <div class="note-body">
          <skeleton-loading />
        </div>
      </div>
    </div>
  </li>
</template>
