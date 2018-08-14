<script>
import { mapActions } from 'vuex';
import Icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  components: {
    Icon,
  },
  directives: {
    tooltip,
  },
  props: {
    path: {
      type: String,
      required: true,
    },
  },
  methods: {
    ...mapActions(['stageChange', 'discardFileChanges']),
  },
};
</script>

<template>
  <div
    v-once
    class="multi-file-discard-btn dropdown"
  >
    <button
      v-tooltip
      :aria-label="__('Stage changes')"
      :title="__('Stage changes')"
      type="button"
      class="btn btn-blank append-right-5 d-flex align-items-center"
      data-container="body"
      data-boundary="viewport"
      data-placement="bottom"
      @click.stop="stageChange(path)"
    >
      <icon
        :size="12"
        name="mobile-issue-close"
      />
    </button>
    <button
      v-tooltip
      :title="__('More actions')"
      type="button"
      class="btn btn-blank d-flex align-items-center"
      data-container="body"
      data-boundary="viewport"
      data-placement="bottom"
      data-toggle="dropdown"
      data-display="static"
    >
      <icon
        :size="12"
        name="ellipsis_h"
      />
    </button>
    <div class="dropdown-menu dropdown-menu-right">
      <ul>
        <li>
          <button
            type="button"
            @click.stop="discardFileChanges(path)"
          >
            {{ __('Discard changes') }}
          </button>
        </li>
      </ul>
    </div>
  </div>
</template>
