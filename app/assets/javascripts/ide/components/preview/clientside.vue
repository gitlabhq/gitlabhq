<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import _ from 'underscore';
import { Manager } from 'smooshpack';
import { listen } from 'codesandbox-api';
import { GlLoadingIcon } from '@gitlab/ui';
import Navigator from './navigator.vue';
import { packageJsonPath } from '../../constants';
import { createPathWithExt } from '../../utils';

export default {
  components: {
    Navigator,
    GlLoadingIcon,
  },
  data() {
    return {
      manager: {},
      loading: false,
      sandpackReady: false,
    };
  },
  computed: {
    ...mapState(['entries', 'promotionSvgPath', 'links']),
    ...mapGetters(['packageJson', 'currentProject']),
    normalizedEntries() {
      return Object.keys(this.entries).reduce((acc, path) => {
        const file = this.entries[path];

        if (file.type === 'tree' || !(file.raw || file.content)) return acc;

        return {
          ...acc,
          [`/${path}`]: {
            code: file.content || file.raw,
          },
        };
      }, {});
    },
    mainEntry() {
      if (!this.packageJson.raw) return false;

      const parsedPackage = JSON.parse(this.packageJson.raw);

      return parsedPackage.main;
    },
    showPreview() {
      return this.mainEntry && !this.loading;
    },
    showEmptyState() {
      return !this.mainEntry && !this.loading;
    },
    showOpenInCodeSandbox() {
      return this.currentProject && this.currentProject.visibility === 'public';
    },
    sandboxOpts() {
      return {
        files: { ...this.normalizedEntries },
        entry: `/${this.mainEntry}`,
        showOpenInCodeSandbox: this.showOpenInCodeSandbox,
      };
    },
  },
  watch: {
    entries: {
      deep: true,
      handler: 'update',
    },
  },
  mounted() {
    this.loading = true;

    return this.loadFileContent(packageJsonPath)
      .then(() => {
        this.loading = false;
      })
      .then(() => this.$nextTick())
      .then(() => this.initPreview());
  },
  beforeDestroy() {
    if (!_.isEmpty(this.manager)) {
      this.manager.listener();
    }
    this.manager = {};

    if (this.listener) {
      this.listener();
    }

    clearTimeout(this.timeout);
    this.timeout = null;
  },
  methods: {
    ...mapActions(['getFileData', 'getRawFileData']),
    ...mapActions('clientside', ['pingUsage']),
    loadFileContent(path) {
      return this.getFileData({ path, makeFileActive: false }).then(() =>
        this.getRawFileData({ path }),
      );
    },
    initPreview() {
      if (!this.mainEntry) return null;

      this.pingUsage();

      return this.loadFileContent(this.mainEntry)
        .then(() => this.$nextTick())
        .then(() => {
          this.initManager('#ide-preview', this.sandboxOpts, {
            fileResolver: {
              isFile: p => Promise.resolve(Boolean(this.entries[createPathWithExt(p)])),
              readFile: p => this.loadFileContent(createPathWithExt(p)).then(content => content),
            },
          });

          this.listener = listen(e => {
            switch (e.type) {
              case 'done':
                this.sandpackReady = true;
                break;
              default:
                break;
            }
          });
        });
    },
    update() {
      if (!this.sandpackReady) return;

      clearTimeout(this.timeout);

      this.timeout = setTimeout(() => {
        if (_.isEmpty(this.manager)) {
          this.initPreview();

          return;
        }

        this.manager.updatePreview(this.sandboxOpts);
      }, 250);
    },
    initManager(el, opts, resolver) {
      this.manager = new Manager(el, opts, resolver);
    },
  },
};
</script>

<template>
  <div class="preview h-100 w-100 d-flex flex-column">
    <template v-if="showPreview">
      <navigator :manager="manager" />
      <div id="ide-preview"></div>
    </template>
    <div
      v-else-if="showEmptyState"
      v-once
      class="d-flex h-100 flex-column align-items-center justify-content-center svg-content"
    >
      <img :src="promotionSvgPath" :alt="s__('IDE|Live Preview')" width="130" height="100" />
      <h3>{{ s__('IDE|Live Preview') }}</h3>
      <p class="text-center">
        {{ s__('IDE|Preview your web application using Web IDE client-side evaluation.') }}
      </p>
      <a
        :href="links.webIDEHelpPagePath"
        class="btn btn-primary"
        target="_blank"
        rel="noopener noreferrer"
      >
        {{ s__('IDE|Get started with Live Preview') }}
      </a>
    </div>
    <gl-loading-icon v-else :size="2" class="align-self-center mt-auto mb-auto" />
  </div>
</template>
