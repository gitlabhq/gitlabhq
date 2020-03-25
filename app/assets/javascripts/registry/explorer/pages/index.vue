<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import { s__ } from '~/locale';

export default {
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
  },
  i18n: {
    garbageCollectionTipText: s__(
      'ContainerRegistry|This Registry contains deleted image tag data. Remember to run  %{docLinkStart}garbage collection%{docLinkEnd} to remove the stale data from storage.',
    ),
  },
  computed: {
    ...mapState(['config']),
    ...mapGetters(['showGarbageCollection']),
  },
  methods: {
    ...mapActions(['setShowGarbageCollectionTip']),
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="showGarbageCollection"
      variant="tip"
      class="my-2"
      @dismiss="setShowGarbageCollectionTip(false)"
    >
      <gl-sprintf :message="$options.i18n.garbageCollectionTipText">
        <template #docLink="{content}">
          <gl-link :href="config.garbageCollectionHelpPagePath" target="_blank">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>

    <transition name="slide">
      <router-view ref="router-view" />
    </transition>
  </div>
</template>
