import Vue from 'vue';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { joinPaths, webIDEUrl } from '~/lib/utils/url_utility';
import WebIdeButton from '~/vue_shared/components/web_ide_link.vue';

export default ({ el, router }) => {
  if (!el) return;

  const { projectPath, ref, isBlob, webIdeUrl, ...options } = convertObjectPropsToCamelCase(
    JSON.parse(el.dataset.options),
  );
  const { webIdePromoPopoverImg } = el.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    router,
    render(h) {
      return h(WebIdeButton, {
        props: {
          isBlob,
          webIdePromoPopoverImg,
          webIdeUrl: isBlob
            ? webIdeUrl
            : webIDEUrl(
                joinPaths('/', projectPath, 'edit', ref, '-', this.$route?.params.path || '', '/'),
              ),
          ...options,
        },
      });
    },
  });
};
