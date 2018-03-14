<script>
import { __ } from '~/locale';

export default {
  props: {
    labelsWebUrl: {
      type: String,
      required: true,
    },
    createLabelTitle: {
      type: String,
      required: false,
      default: () => __('Create new label'),
    },
    manageLabelsTitle: {
      type: String,
      required: false,
      default: () => __('Manage labels'),
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
          {{ createLabelTitle }}
        </a>
      </li>
      <li>
        <a
          data-is-link="true"
          class="dropdown-external-link"
          :href="labelsWebUrl"
        >
          {{ manageLabelsTitle }}
        </a>
      </li>
    </ul>
  </div>
</template>
