<script>
export default {};
</script>

<template>
  <div class="row gl-mt-5">
    <div class="col-lg-4">
      <h4 class="gl-mt-0">
        {{ __('Comment templates') }}
      </h4>
      <p>
        {{
          __(
            'Comment templates can be used when creating comments inside issues, merge requests, and epics.',
          )
        }}
      </p>
    </div>
    <div class="col-lg-8">
      <keep-alive><router-view /></keep-alive>
    </div>
  </div>
</template>
