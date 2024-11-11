<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { n__ } from '~/locale';
import { SOLO_OWNED_ORGANIZATIONS_REQUESTED_COUNT } from '../constants';

export default {
  components: { GlSprintf, GlLink },
  props: {
    organizations: {
      type: Object,
      required: true,
    },
  },

  computed: {
    nodes() {
      return this.organizations.nodes;
    },
    count() {
      return this.organizations.count;
    },
    extrasCount() {
      if (this.count <= SOLO_OWNED_ORGANIZATIONS_REQUESTED_COUNT) {
        return 0;
      }

      return Math.abs(SOLO_OWNED_ORGANIZATIONS_REQUESTED_COUNT - this.count);
    },
    message() {
      if (this.extrasCount > 0) {
        return n__(
          'Organization|Organizations must have at least one owner. To delete the user, first assign a new owner to %{links} %{boldStart}and%{boldEnd} %{extrasCount} %{boldStart}other Organization%{boldEnd}.',
          'Organization|Organizations must have at least one owner. To delete the user, first assign a new owner to %{links} %{boldStart}and%{boldEnd} %{extrasCount} %{boldStart}other Organizations%{boldEnd}.',
          this.extrasCount,
        );
      }

      return n__(
        'Organization|Organizations must have at least one owner. To delete the user, first assign a new owner to %{lastLink}.',
        'Organization|Organizations must have at least one owner. To delete the user, first assign a new owner to %{links} %{boldStart}and%{boldEnd} %{lastLink}.',
        this.count,
      );
    },
    lastOrganizationForLink() {
      return this.nodes[this.nodes.length - 1];
    },
    organizationsForLinks() {
      if (this.extrasCount > 0) {
        return this.nodes;
      }

      return this.nodes.slice(0, -1);
    },
  },
};
</script>

<template>
  <p>
    <gl-sprintf :message="message">
      <template #links>
        <template v-for="organization in organizationsForLinks">
          <gl-link :key="organization.webUrl" class="gl-font-bold" :href="organization.webUrl">{{
            organization.name
          }}</gl-link
          ><template v-if="organizationsForLinks.length > 1">, </template>
        </template>
      </template>
      <template #lastLink>
        <gl-link class="gl-font-bold" :href="lastOrganizationForLink.webUrl">{{
          lastOrganizationForLink.name
        }}</gl-link>
      </template>
      <template #extrasCount
        ><span class="gl-font-bold">{{ extrasCount }}</span></template
      >
      <template #bold="{ content }">
        <span class="gl-font-bold">{{ content }}</span>
      </template>
    </gl-sprintf>
  </p>
</template>
