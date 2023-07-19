<script>
export default {};
</script>

<template>
  <div class="settings-section gl-mt-3">
    <div class="settings-sticky-header">
      <div class="settings-sticky-header-inner">
        <h4 class="gl-my-0">
          {{ __('Comment templates') }}
        </h4>
      </div>
    </div>
    <p class="gl-text-secondary">
      {{
        __(
          'Comment templates can be used when creating comments inside issues, merge requests, and epics.',
        )
      }}
    </p>
    <keep-alive><router-view /></keep-alive>
  </div>
</template>
