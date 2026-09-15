<script>
import { GlDisclosureDropdown } from '@gitlab/ui';

// Literal class names so Tailwind emits them; `!` overrides GitLab UI's default gl-px-3 item padding.
// Index is the heading level relative to the first heading (0..5).
const HEADING_PADDING_CLASSES = [
  '!gl-pl-5',
  '!gl-pl-6',
  '!gl-pl-7',
  '!gl-pl-8',
  '!gl-pl-9',
  '!gl-pl-10',
];

function getHeaderNumber(el) {
  return parseInt(el.tagName.match(/\d+/)[0], 10);
}

export default {
  name: 'TableContents',
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
    const fileHolder = this.$el.closest('.file-holder');
    this.blobViewer = fileHolder?.querySelector('.blob-viewer');
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
      const headers = [...this.blobViewer.querySelectorAll('h1,h2,h3,h4,h5,h6')];

      if (headers.length === 0) {
        return;
      }

      const firstHeader = getHeaderNumber(headers[0]);

      this.items = headers
        .filter((el) => el.querySelector('a.anchor'))
        .map((el) => {
          const relativeLevel = Math.max(getHeaderNumber(el) - firstHeader, 0);
          let href;
          const anchor = el.querySelector('a.anchor');
          // Check if this is AsciiDoc (heading has id) or Markdown / other markup (anchor has id)
          if (el.id) {
            // AsciiDoc: use anchor's href
            href = anchor.getAttribute('href');
          } else {
            // Markdown and other markup: use anchor's id with #
            href = `#${anchor.getAttribute('id')}`;
          }

          return {
            text: el.textContent.trim(),
            href,
            extraAttrs: {
              class: HEADING_PADDING_CLASSES[relativeLevel],
            },
          };
        });
    },
  },
};
</script>

<template>
  <div class="gl-contents">
    <gl-disclosure-dropdown
      v-if="!isHidden && items.length"
      :toggle-text="__('Table of contents')"
      text-sr-only
      icon="list-bulleted"
      class="!gl-pr-0"
      :items="items"
    />
  </div>
</template>
