<script>
export default {
  props: {
    labelsWebUrl: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div class="dropdown-footer">
    <ul class="dropdown-footer-list">
      <li>
        <a
          href="#"
          class="dropdown-toggle-page"
        >
          {{ __('Create new label') }}
        </a>
      </li>
      <li>
        <a
          data-is-link="true"
          class="dropdown-external-link"
          :href="labelsWebUrl"
        >
          {{ __('Manage labels') }}
        </a>
      </li>
    </ul>
  </div>
</template>
