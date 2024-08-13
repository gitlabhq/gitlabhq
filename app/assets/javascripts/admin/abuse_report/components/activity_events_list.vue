<script>
import { HISTORY_ITEMS_I18N } from '../constants';

export default {
  name: 'ActivityEventsList',
  i18n: HISTORY_ITEMS_I18N,
};
</script>

<template>
  <!-- The styles `issuable-discussion`, `timeline`, `main-notes-list` and `notes` used below
       are declared in app/assets/stylesheets/pages/notes.scss -->
  <section class="issuable-discussion gl-pt-6">
    <h2 class="gl-mb-4 gl-mt-0 gl-text-size-h1">{{ $options.i18n.activity }}</h2>
    <ul class="timeline main-notes-list notes">
      <slot name="history-items"></slot>
    </ul>
  </section>
</template>
