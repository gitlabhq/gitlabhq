import { defineStore } from 'pinia';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { whatsNewPath } from '~/lib/utils/path_helpers/routes';
import { __ } from '~/locale';

export const useWhatsNew = defineStore('whatsNew', {
  state: () => ({
    open: false,
    features: [],
    fetching: false,
    pageInfo: {
      nextPage: null,
    },
    readArticles: [],
  }),
  actions: {
    closeDrawer() {
      this.open = false;
    },
    openDrawer() {
      this.open = true;
    },
    async fetchItems({ page, versionDigest } = { page: null, versionDigest: null }) {
      if (this.fetching) {
        return;
      }

      this.fetching = true;

      try {
        const { data, headers } = await axios.get(whatsNewPath(), {
          params: {
            page,
            v: versionDigest,
          },
        });

        const featuresPerRelease = [{ releaseHeading: true, release: data[0]?.release }, ...data];
        this.features = this.features.concat(featuresPerRelease);

        const normalizedHeaders = normalizeHeaders(headers);
        const { nextPage } = parseIntPagination(normalizedHeaders);
        this.pageInfo = { nextPage };
      } catch (error) {
        this.pageInfo = { nextPage: null };
        createAlert({
          message: __("Failed to load What's new features. Refresh the page and try again."),
          error,
          captureError: true,
        });
      } finally {
        this.fetching = false;
      }
    },
    setReadArticles(readArticles) {
      this.readArticles = readArticles;
    },
  },
});
