<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';

function getHeaderNumber(el) {
  return parseInt(el.tagName.match(/\d+/)[0], 10);
}

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  data() {
    return {
      isHidden: false,
      items: [],
    };
  },
  mounted() {
    this.blobViewer = document.querySelector('.blob-viewer[data-type="rich"]');

    this.observer = new MutationObserver(() => {
      if (this.blobViewer.classList.contains('hidden')) {
        this.isHidden = true;
      } else if (this.blobViewer.getAttribute('data-loaded') === 'true') {
        this.isHidden = false;
        this.generateHeaders();
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

      if (headers.length) {
        const firstHeader = getHeaderNumber(headers[0]);

        headers.forEach((el) => {
          this.items.push({
            text: el.textContent.trim(),
            anchor: el.querySelector('a').getAttribute('id'),
            spacing: Math.max((getHeaderNumber(el) - firstHeader) * 8, 0),
          });
        });
      }
    },
  },
};
</script>

<template>
  <gl-dropdown v-if="!isHidden && items.length" icon="list-bulleted" class="gl-mr-2" lazy>
    <gl-dropdown-item v-for="(item, index) in items" :key="index" :href="`#${item.anchor}`">
      <span
        :style="{ 'padding-left': `${item.spacing}px` }"
        class="gl-display-block"
        data-testid="tableContentsLink"
      >
        {{ item.text }}
      </span>
    </gl-dropdown-item>
  </gl-dropdown>
</template>
