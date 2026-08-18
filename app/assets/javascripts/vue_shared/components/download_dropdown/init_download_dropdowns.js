import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import SourceCodeDownloadDropdown from '~/vue_shared/components/download_dropdown/download_dropdown.vue';

export default function initSourceCodeDropdowns() {
  const dropdowns = document.querySelectorAll('.js-source-code-dropdown');

  return dropdowns.forEach((el, index) => {
    const { downloadLinks, downloadArtifacts, cssClass } = el.dataset;

    return initVueApp({
      el,
      name: `SourceCodeDropdown${index + 1}`,
      provide: {
        downloadLinks,
        downloadArtifacts,
        cssClass,
      },
      component: SourceCodeDownloadDropdown,
      props: {
        downloadLinks: JSON.parse(downloadLinks) || [],
        downloadArtifacts: JSON.parse(downloadArtifacts) || [],
        cssClass,
      },
    });
  });
}
