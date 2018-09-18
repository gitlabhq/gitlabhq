<script>
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'SecurityDashboardActionButtons',
  components: {
    Icon,
  },
  props: {
    vulnerability: {
      type: Object,
      required: true,
    },
  },
  methods: {
    openModal() {
      // TODO: Open the modal
    },
    newIssue() {
      this.$store.dispatch('newIssue', this.vulnerability);
    },
    dismissVulnerability() {
      this.$store.dispatch('dismissVulnerability', this.vulnerability);
    },
  },
};
</script>

<template>
  <div>
    <button
      :aria-label="s__('Reports|More info')"
      class="btn btn-secondary js-more-info"
      type="button"
      @click="openModal()"
    >
      <icon
        name="external-link"
      />
    </button>
    <button
      :aria-label="s__('Reports|New Issue')"
      class="btn btn-inverted btn-info js-new-issue"
      type="button"
      @click="newIssue()"
    >
      <icon
        name="issue-new"
      />
    </button>
    <button
      :aria-label="s__('Reports|Dismiss Vulnerability')"
      class="btn btn-inverted btn-remove js-dismiss-vulnerability"
      type="button"
      @click="dismissVulnerability()"
    >
      <icon
        name="cancel"
      />
    </button>
  </div>
</template>
