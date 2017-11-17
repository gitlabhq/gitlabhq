<script>
  import { mapActions, mapGetters } from 'vuex';

  export default {
    name: 'ErrorViewer',
    computed: {
      ...mapGetters([
        'activeFile',
        'activeFileCurrentViewer',
      ]),
      optionLinks() {
        const links = [];

        if (this.activeFileCurrentViewer.renderError === 'collapsed') {
          links.push({
            href: '#',
            text: 'load it anyway',
            callback: () => this.getFileHTML({
              file: this.activeFile,
              expanded: true,
            }),
          });
        }

        if (
          this.activeFile.simple.name === 'text' &&
          (this.activeFileCurrentViewer.renderError === 'server_side_but_stored_externally' || this.activeFileCurrentViewer.renderError === 'too_large')
        ) {
          links.push({
            href: '#',
            text: 'view the source',
            callback: () => this.changeFileViewer({
              file: this.activeFile,
              type: 'simple',
            }),
          });
        }

        links.push({
          href: this.activeFile.rawPath,
          text: 'download it',
        });

        return links;
      },
    },
    methods: {
      ...mapActions([
        'changeFileViewer',
        'getFileHTML',
      ]),
      linkClick(e, link) {
        if (!link.callback) return;

        e.preventDefault();

        link.callback();
      },
    },
  };
</script>

<template>
  <div
    class="nothing-here-block"
  >
    The {{ activeFileCurrentViewer.name }} could not be displayed because {{ activeFileCurrentViewer.renderErrorReason }}.
    You can
    <template
      v-for="(link, index) in optionLinks"
    >
      <template
        v-if="index === optionLinks.length - 1 && optionLinks.length !== 1"
      >, or</template>
      <template
        v-else-if="index !== 0 && optionLinks.length !== 1"
      >, </template>
      <a
        :href="link.href"
        @click="linkClick($event, link)"
      >{{ link.text }}</a>
    </template>
    instead.
  </div>
</template>
