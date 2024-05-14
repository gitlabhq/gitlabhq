import Vue from 'vue';
import SourceCodeDownloadDropdown from '~/vue_shared/components/download_dropdown/download_dropdown.vue';

export default function initSourceCodeDropdowns() {
  const dropdowns = document.querySelectorAll('.js-source-code-dropdown');

  return dropdowns.forEach((el, index) => {
    const { downloadLinks, downloadArtifacts, cssClass } = el.dataset;

    return new Vue({
      el,
      name: `SourceCodeDropdown${index + 1}`,
      provide: {
        downloadLinks,
        downloadArtifacts,
        cssClass,
      },
      render(createElement) {
        return createElement(SourceCodeDownloadDropdown, {
          props: {
            downloadLinks: JSON.parse(downloadLinks) || [],
            downloadArtifacts: JSON.parse(downloadArtifacts) || [],
            cssClass,
          },
        });
      },
    });
  });
}
