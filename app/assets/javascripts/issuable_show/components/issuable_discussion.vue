<script>
export default {
  name: 'IssuableDiscussion',
};
</script>

<template>
  <section class="issuable-discussion">
    <div>
      <ul class="notes main-notes-list timeline">
        <slot name="discussion"></slot>
      </ul>
    </div>
  </section>
</template>
