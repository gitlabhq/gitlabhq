<script>
  import TimeagoTooltiop from '~/vue_shared/components/time_ago_tooltip.vue';

  export default {
    components: {
      TimeagoTooltiop,
    },
    props: {
      // @build.artifacts_expired?
      haveArtifactsExpired: {
        type: Boolean,
        required: true,
      },
      // @build.has_expiring_artifacts?
      willArtifactsExpire: {
        type: Boolean,
        required: true,
      },
      expireAt: {
        type: String,
        required: false,
        default: null,
      },
      keepArtifactsPath: {
        type: String,
        required: false,
        default: null,
      },
      downloadArtifactsPath: {
        type: String,
        required: false,
        default: null,
      },
      browseArtifactsPath: {
        type: String,
        required: false,
        default: null,
      },
    },
  };
</script>
<template>
  <div class="block">
    <div class="title">
      {{ s__('Job|Job artifacts') }}
    </div>

    <p
      v-if="haveArtifactsExpired"
      class="js-artifacts-removed build-detail-row"
    >
      {{ s__('Job|The artifacts were removed') }}
    </p>
    <p
      v-else-if="willArtifactsExpire"
      class="js-artifacts-will-be-removed build-detail-row"
    >
      {{ s__('Job|The artifacts will be removed') }}
    </p>

    <timeago-tooltiop
      v-if="expireAt"
      :time="expireAt"
    />

    <div
      class="btn-group d-flex"
      role="group"
    >
      <a
        v-if="keepArtifactsPath"
        :href="keepArtifactsPath"
        class="js-keep-artifacts btn btn-sm btn-default"
        data-method="post"
      >
        {{ s__('Job|Keep') }}
      </a>

      <a
        v-if="downloadArtifactsPath"
        :href="downloadArtifactsPath"
        class="js-download-artifacts btn btn-sm btn-default"
        download
        rel="nofollow"
      >
        {{ s__('Job|Download') }}
      </a>

      <a
        v-if="browseArtifactsPath"
        :href="browseArtifactsPath"
        class="js-browse-artifacts btn btn-sm btn-default"
      >
        {{ s__('Job|Browse') }}
      </a>
    </div>
  </div>
</template>
