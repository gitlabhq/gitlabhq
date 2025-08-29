<script>
import { GlDisclosureDropdown } from '@gitlab/ui';

function getHeaderNumber(el) {
  return parseInt(el.tagName.match(/\d+/)[0], 10);
}

export default {
  components: {
    GlDisclosureDropdown,
  },
  data() {
    return {
      isHidden: false,
      items: [],
    };
  },
  mounted() {
    this.blobViewer = document.querySelector('.blob-viewer[data-type="rich"]');
    const blobViewerAttr = (attr) => this.blobViewer.getAttribute(attr);

    this.observer = new MutationObserver(() => {
      if (this.blobViewer.classList.contains('hidden') || blobViewerAttr('data-type') !== 'rich') {
        this.isHidden = true;
      } else if (blobViewerAttr('data-loaded') === 'true') {
        this.isHidden = false;
        this.generateHeaders();
        this.observer.disconnect();
      }
    });

    if (this.blobViewer) {
      this.observer.observe(this.blobViewer, {
        attributes: true,
      });
    }
  },
  beforeDestroy() {
    if (this.observer) {
      this.observer.disconnect();
    }
  },
  methods: {
    generateHeaders() {
      const BASE_PADDING = 16;
      const headers = [...this.blobViewer.querySelectorAll('h1,h2,h3,h4,h5,h6')];

      if (headers.length === 0) {
        return;
      }

      const firstHeader = getHeaderNumber(headers[0]);

      this.items = headers
        .filter((el) => el.querySelector('a'))
        .map((el) => {
          let href;
          const anchor = el.querySelector('a');
          // Check if this is AsciiDoc (heading has id) or Markdown (anchor has id)
          if (el.id) {
            // AsciiDoc: use anchor's href
            href = anchor.getAttribute('href');
          } else {
            // Markdown: use anchor's id with #
            href = `#${anchor.getAttribute('id')}`;
          }

          return {
            text: el.textContent.trim(),
            href,
            extraAttrs: {
              style: {
                paddingLeft: `${BASE_PADDING + Math.max((getHeaderNumber(el) - firstHeader) * 8, 0)}px`,
              },
            },
          };
        });
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    v-if="!isHidden && items.length"
    :toggle-text="__('Table of contents')"
    text-sr-only
    icon="list-bulleted"
    class="!gl-pr-0"
    :items="items"
  />
</template>
