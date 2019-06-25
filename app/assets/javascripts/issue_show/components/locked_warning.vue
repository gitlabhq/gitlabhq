<script>
export default {
  computed: {
    currentPath() {
      return window.location.pathname;
    },
  },
};
</script>

<template>
  <div class="alert alert-danger">
    {{ sprintf(__("Someone edited the issue at the same time you did. Please check out
    %{linkStart}%the issue%{linkEnd} and make sure your changes will not unintentionally remove
    theirs."), { linkStart: `<a href="${currentPath}" target="_blank" rel="nofollow">` linkEnd: '</a
    >', }) }}
  </div>
</template>
