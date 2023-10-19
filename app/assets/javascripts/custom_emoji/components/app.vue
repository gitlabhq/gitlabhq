<script>
export default {};
</script>

<template>
  <div class="row gl-mt-5">
    <div class="col-12">
      <h4 class="gl-mt-0">
        {{ __('Custom emoji') }}
      </h4>
      <p>{{ __('Custom emoji will be available to use in every project in the group.') }}</p>
      <router-view />
    </div>
  </div>
</template>
