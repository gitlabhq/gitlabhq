<script>
export default {
  name: 'SastContainerInfo',
};
</script>
<template>
  <p
    class="prepend-top-10 prepend-left-10 report-block-info js-mr-code-quality-info"
  >
    {{ s__('ciReport|Unapproved vulnerabilities (red) can be marked as approved.') }}
    <a
      href="https://gitlab.com/gitlab-org/clair-scanner#example-whitelist-yaml-file"
      target="_blank"
      rel="noopener noreferrer nofollow"
    >
      {{ s__('ciReport|Learn more about whitelisting') }}
    </a>
  </p>
</template>
