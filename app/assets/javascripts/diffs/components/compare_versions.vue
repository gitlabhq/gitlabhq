<script>
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    Icon,
  },
};
</script>

<template>
  <div class="mr-version-controls">
    <div class="mr-version-menus-container content-block">
      Changes between
      <span class="dropdown inline mr-version-dropdown">
        <a
          class="dropdown-toggle btn btn-default"
          data-toggle="dropdown"
          aria-expanded="false"
        >
          <span>
            latest version
          </span>
          <Icon
            name="angle-down"
            size="12"
          />
        </a>
      </span>
      and
      <span class="dropdown inline mr-version-compare-dropdown">
        <a
          class="btn btn-default dropdown-toggle"
          data-toggle="dropdown"
          aria-expanded="false"
        >
          <span class="ref-name">master</span>
          <Icon
            name="angle-down"
            size="12"
          />
        </a>
      </span>
    </div>
  </div>
</template>
